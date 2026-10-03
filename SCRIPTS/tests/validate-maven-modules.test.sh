#!/usr/bin/env sh

set -u

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SUBJECT="$TEST_DIR/../validate-maven-modules.sh"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/validate-maven-modules-tests.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

PASSED=0
FAILED=0
STATUS=0
OUTPUT=""
FIXTURE=""

fail() {
    printf '\n    %s\n' "$1" >&2
    return 1
}

assert_status() {
    expected=$1
    if [ "$STATUS" -ne "$expected" ]; then
        fail "Expected exit status $expected, got $STATUS. Output: $OUTPUT"
    fi
}

assert_contains() {
    haystack=$1
    needle=$2
    case "$haystack" in
        *"$needle"*) return 0 ;;
        *) fail "Expected output to contain: $needle. Actual output: $haystack" ;;
    esac
}

assert_not_contains() {
    haystack=$1
    needle=$2
    case "$haystack" in
        *"$needle"*) fail "Expected output not to contain: $needle. Actual output: $haystack" ;;
        *) return 0 ;;
    esac
}

assert_file_contains() {
    file=$1
    needle=$2
    if ! grep -Fq "$needle" "$file"; then
        fail "Expected $file to contain: $needle"
    fi
}

assert_occurrences() {
    file=$1
    needle=$2
    expected=$3
    actual=$(grep -F "$needle" "$file" 2>/dev/null | wc -l | awk '{ print $1 }')
    if [ "$actual" -ne "$expected" ]; then
        fail "Expected $needle to occur $expected time(s) in $file, got $actual."
    fi
}

new_fixture() {
    name=$1
    FIXTURE="$TEST_ROOT/$name"
    mkdir -p "$FIXTURE/SCRIPTS"
    cp "$SUBJECT" "$FIXTURE/SCRIPTS/validate-maven-modules.sh"
}

create_module() {
    module=$1
    mkdir -p "$FIXTURE/$module"
    cat > "$FIXTURE/$module/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>fixture-module</artifactId>
    <version>1.0.0</version>
</project>
EOF
}

create_root_pom_without_modules() {
    cat > "$FIXTURE/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>existing-aggregator</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>
    <description>keep this setting</description>
</project>
EOF
}

run_subject() {
    OUTPUT=$(sh "$FIXTURE/SCRIPTS/validate-maven-modules.sh" "$@" 2>&1)
    STATUS=$?
}

test_default_fails_when_root_pom_is_missing() {
    new_fixture default-without-root
    create_module alpha

    run_subject

    assert_status 1 || return 1
    assert_contains "$OUTPUT" 'Root pom.xml does not exist' || return 1
}

test_check_lost_lists_modules_and_ignores_generated_poms() {
    new_fixture check-lost
    create_module alpha
    create_module nested/beta
    create_module target/generated
    create_module .git/copied

    run_subject --checkLost

    assert_status 1 || return 1
    assert_contains "$OUTPUT" 'Missing Maven submodules (2):' || return 1
    assert_contains "$OUTPUT" '  - alpha' || return 1
    assert_contains "$OUTPUT" '  - nested/beta' || return 1
    assert_not_contains "$OUTPUT" 'target/generated' || return 1
    assert_not_contains "$OUTPUT" '.git/copied' || return 1
}

test_fix_creates_root_pom_and_is_idempotent() {
    new_fixture fix-new-root
    create_module alpha
    create_module nested/beta

    run_subject --fix

    assert_status 0 || return 1
    assert_contains "$OUTPUT" 'Added 2 Maven submodule(s)' || return 1
    assert_file_contains "$FIXTURE/pom.xml" '<packaging>pom</packaging>' || return 1
    assert_occurrences "$FIXTURE/pom.xml" '<module>alpha</module>' 1 || return 1
    assert_occurrences "$FIXTURE/pom.xml" '<module>nested/beta</module>' 1 || return 1
    checksum_before=$(cksum "$FIXTURE/pom.xml")

    run_subject --fix

    assert_status 0 || return 1
    assert_contains "$OUTPUT" 'pom.xml was not changed' || return 1
    checksum_after=$(cksum "$FIXTURE/pom.xml")
    if [ "$checksum_before" != "$checksum_after" ]; then
        fail 'The second --fix invocation changed pom.xml.'
        return 1
    fi

    run_subject
    assert_status 0 || return 1
    assert_contains "$OUTPUT" 'All Maven submodules are declared' || return 1
}

test_fix_adds_modules_section_to_existing_pom() {
    new_fixture fix-existing-root
    create_root_pom_without_modules
    create_module alpha

    run_subject --fix

    assert_status 0 || return 1
    assert_file_contains "$FIXTURE/pom.xml" '<artifactId>existing-aggregator</artifactId>' || return 1
    assert_file_contains "$FIXTURE/pom.xml" '<description>keep this setting</description>' || return 1
    assert_file_contains "$FIXTURE/pom.xml" '<modules>' || return 1
    assert_occurrences "$FIXTURE/pom.xml" '<module>alpha</module>' 1 || return 1
}

test_fix_only_adds_missing_modules() {
    new_fixture fix-partial-root
    create_module alpha
    create_module beta
    cat > "$FIXTURE/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>partial-aggregator</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>
    <modules>
        <module>alpha</module>
    </modules>
</project>
EOF

    run_subject --fix

    assert_status 0 || return 1
    assert_contains "$OUTPUT" 'Added 1 Maven submodule(s)' || return 1
    assert_occurrences "$FIXTURE/pom.xml" '<module>alpha</module>' 1 || return 1
    assert_occurrences "$FIXTURE/pom.xml" '<module>beta</module>' 1 || return 1
}

test_declared_module_paths_are_normalized() {
    new_fixture normalized-path
    create_module nested/beta
    cat > "$FIXTURE/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>normalized-aggregator</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>
    <modules>
        <module>./nested\beta/pom.xml</module>
    </modules>
</project>
EOF

    run_subject

    assert_status 0 || return 1
    assert_contains "$OUTPUT" 'All Maven submodules are declared' || return 1
}

test_invalid_arguments_return_usage_error() {
    new_fixture invalid-arguments

    run_subject --unknown
    assert_status 2 || return 1
    assert_contains "$OUTPUT" 'Unknown option: --unknown' || return 1

    run_subject --fix --checkLost
    assert_status 2 || return 1
    assert_contains "$OUTPUT" 'Only one option may be specified' || return 1
}

run_test() {
    description=$1
    function_name=$2
    printf 'TEST: %s ... ' "$description"
    if "$function_name"; then
        PASSED=$((PASSED + 1))
        printf 'PASS\n'
    else
        FAILED=$((FAILED + 1))
        printf 'FAIL\n'
    fi
}

if [ ! -f "$SUBJECT" ]; then
    printf 'Subject script not found: %s\n' "$SUBJECT" >&2
    exit 2
fi

run_test 'default mode rejects a missing root pom.xml' test_default_fails_when_root_pom_is_missing
run_test '--checkLost lists only real Maven modules' test_check_lost_lists_modules_and_ignores_generated_poms
run_test '--fix creates a root POM and remains idempotent' test_fix_creates_root_pom_and_is_idempotent
run_test '--fix preserves and extends an existing root POM' test_fix_adds_modules_section_to_existing_pom
run_test '--fix adds only modules that are missing' test_fix_only_adds_missing_modules
run_test 'declared module paths are normalized before comparison' test_declared_module_paths_are_normalized
run_test 'invalid arguments return exit status 2' test_invalid_arguments_return_usage_error

printf '\nResult: %s passed, %s failed\n' "$PASSED" "$FAILED"

if [ "$FAILED" -ne 0 ]; then
    exit 1
fi
