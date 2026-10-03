#!/usr/bin/env sh

# Maven 聚合模組檢查工具
#
# 使用方式（可從任意目錄執行）：
#   sh SCRIPTS/validate-maven-modules.sh
#       檢查所有 Maven 子模組是否已宣告於專案根目錄的 pom.xml，
#       並檢查 pom.xml 宣告的模組是否仍存在於磁碟；若不一致則回傳 exit code 1。
#
#   sh SCRIPTS/validate-maven-modules.sh --checkLost
#       列出未宣告的 Maven 子模組，以及已宣告但不存在於磁碟的模組。
#
#   sh SCRIPTS/validate-maven-modules.sh --fix
#       補入未宣告的子模組並移除不存在的模組宣告；若根 pom.xml 不存在則建立聚合 POM。
#
# 若目前位於 SCRIPTS 目錄，也可改用：
#   ./validate-maven-modules.sh [--checkLost | --fix]

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
ROOT_POM="$PROJECT_ROOT/pom.xml"
MODE="check"

usage() {
    cat <<'EOF'
Usage: ./validate-maven-modules.sh [--checkLost | --fix]

  no option     Check whether pom.xml declarations and modules on disk are in sync.
  --checkLost   List undeclared modules and declarations whose modules no longer exist.
  --fix         Add undeclared modules and remove stale module declarations.
EOF
}

case "${1-}" in
    "") ;;
    --checkLost) MODE="list" ;;
    --fix) MODE="fix" ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        printf 'Unknown option: %s\n\n' "$1" >&2
        usage >&2
        exit 2
        ;;
esac

if [ "$#" -gt 1 ]; then
    printf 'Only one option may be specified.\n\n' >&2
    usage >&2
    exit 2
fi

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/validate-maven-modules.XXXXXX")
trap 'rm -rf "$WORK_DIR"' EXIT HUP INT TERM

DISCOVERED="$WORK_DIR/discovered"
DECLARED="$WORK_DIR/declared"
UNDECLARED="$WORK_DIR/undeclared"
STALE="$WORK_DIR/stale"

# Every pom.xml below the repository root is considered a Maven submodule.
# Build output and VCS metadata are excluded so generated/copied POMs are ignored.
find "$PROJECT_ROOT" \
    \( -type d \( -name .git -o -name target \) -prune \) -o \
    \( -type f -name pom.xml ! -path "$ROOT_POM" -print \) |
    sed "s#^$PROJECT_ROOT/##; s#/pom.xml\$##" |
    LC_ALL=C sort -u > "$DISCOVERED"

read_declared_modules() {
    if [ ! -f "$ROOT_POM" ]; then
        : > "$DECLARED"
        return
    fi

    grep -oE '<module>[[:space:]]*[^<]+[[:space:]]*</module>' "$ROOT_POM" 2>/dev/null |
        sed -E 's#^<module>[[:space:]]*##; s#[[:space:]]*</module>$##; s#\\#/#g; s#^\./##; s#/*$##; s#/pom\.xml$##' |
        LC_ALL=C sort -u > "$DECLARED" || :
}

find_module_differences() {
    read_declared_modules
    awk 'FILENAME == ARGV[1] { declared[$0] = 1; next } !($0 in declared)' "$DECLARED" "$DISCOVERED" > "$UNDECLARED"
    awk 'FILENAME == ARGV[1] { discovered[$0] = 1; next } !($0 in discovered)' "$DISCOVERED" "$DECLARED" > "$STALE"
}

line_count() {
    awk 'END { print NR + 0 }' "$1"
}

create_root_pom() {
    cat > "$ROOT_POM" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.ccd</groupId>
    <artifactId>ccd-spring-boot-aggregator</artifactId>
    <version>25.0.1-SNAPSHOT</version>
    <packaging>pom</packaging>

    <modules>
    </modules>
</project>
EOF
}

add_missing_modules() {
    ADDITIONS="$WORK_DIR/additions"
    : > "$ADDITIONS"
    while IFS= read -r module; do
        escaped=$(printf '%s' "$module" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        printf '        <module>%s</module>\n' "$escaped" >> "$ADDITIONS"
    done < "$UNDECLARED"

    UPDATED_POM="$WORK_DIR/pom.xml"
    if grep -q '</modules>' "$ROOT_POM"; then
        awk '
            /<\/modules>/ && !inserted {
                while ((getline line < additions) > 0) print line
                close(additions)
                inserted = 1
            }
            { print }
            END { if (!inserted) exit 1 }
        ' additions="$ADDITIONS" "$ROOT_POM" > "$UPDATED_POM"
    else
        awk '
            /<\/project>/ && !inserted {
                print "    <modules>"
                while ((getline line < additions) > 0) print line
                close(additions)
                print "    </modules>"
                inserted = 1
            }
            { print }
            END { if (!inserted) exit 1 }
        ' additions="$ADDITIONS" "$ROOT_POM" > "$UPDATED_POM"
    fi
    mv "$UPDATED_POM" "$ROOT_POM"
}

remove_stale_modules() {
    UPDATED_POM="$WORK_DIR/pom-without-stale-modules.xml"
    awk '
        FILENAME == ARGV[1] {
            stale[$0] = 1
            next
        }
        {
            original = $0
            remaining = $0
            result = ""
            while (match(remaining, /<module>[[:space:]]*[^<]+[[:space:]]*<\/module>/)) {
                prefix = substr(remaining, 1, RSTART - 1)
                element = substr(remaining, RSTART, RLENGTH)
                remaining = substr(remaining, RSTART + RLENGTH)

                module = element
                sub(/^<module>[[:space:]]*/, "", module)
                sub(/[[:space:]]*<\/module>$/, "", module)
                gsub(/\\/, "/", module)
                sub(/^\.\//, "", module)
                sub(/\/+$/, "", module)
                sub(/\/pom[.]xml$/, "", module)

                result = result prefix
                if (!(module in stale)) result = result element
            }
            result = result remaining
            if (original ~ /<module>/ && result ~ /^[[:space:]]*$/) next
            print result
        }
    ' "$STALE" "$ROOT_POM" > "$UPDATED_POM"
    mv "$UPDATED_POM" "$ROOT_POM"
}

find_module_differences
UNDECLARED_COUNT=$(line_count "$UNDECLARED")
STALE_COUNT=$(line_count "$STALE")

case "$MODE" in
    check)
        if [ ! -f "$ROOT_POM" ]; then
            printf 'ERROR: Root pom.xml does not exist. Run with --checkLost or --fix.\n' >&2
            exit 1
        fi
        if [ "$UNDECLARED_COUNT" -ne 0 ] || [ "$STALE_COUNT" -ne 0 ]; then
            printf 'ERROR: pom.xml is out of sync: %s Maven submodule(s) are undeclared; %s declared Maven module(s) are missing on disk. Run with --checkLost for details.\n' \
                "$UNDECLARED_COUNT" "$STALE_COUNT" >&2
            exit 1
        fi
        printf 'OK: All Maven submodules are declared and exist on disk.\n'
        ;;
    list)
        if [ "$UNDECLARED_COUNT" -eq 0 ] && [ "$STALE_COUNT" -eq 0 ]; then
            printf 'No Maven module differences found.\n'
            exit 0
        fi
        if [ "$UNDECLARED_COUNT" -ne 0 ]; then
            printf 'Missing Maven submodules (%s):\n' "$UNDECLARED_COUNT"
            sed 's/^/  - /' "$UNDECLARED"
        fi
        if [ "$STALE_COUNT" -ne 0 ]; then
            printf 'Declared Maven modules missing on disk (%s):\n' "$STALE_COUNT"
            sed 's/^/  - /' "$STALE"
        fi
        exit 1
        ;;
    fix)
        CREATED_ROOT_POM=0
        if [ ! -f "$ROOT_POM" ]; then
            create_root_pom
            CREATED_ROOT_POM=1
        fi
        if [ "$STALE_COUNT" -ne 0 ]; then
            remove_stale_modules
            printf 'Removed %s stale Maven module declaration(s):\n' "$STALE_COUNT"
            sed 's/^/  - /' "$STALE"
        fi
        if [ "$UNDECLARED_COUNT" -ne 0 ]; then
            add_missing_modules
            printf 'Added %s Maven submodule(s) to pom.xml:\n' "$UNDECLARED_COUNT"
            sed 's/^/  - /' "$UNDECLARED"
        fi
        if [ "$UNDECLARED_COUNT" -eq 0 ] && [ "$STALE_COUNT" -eq 0 ] && [ "$CREATED_ROOT_POM" -eq 0 ]; then
            printf 'No missing Maven submodules; pom.xml was not changed.\n'
            exit 0
        fi
        ;;
esac
