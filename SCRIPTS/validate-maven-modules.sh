#!/usr/bin/env sh

# Maven 聚合模組檢查工具
#
# 使用方式（可從任意目錄執行）：
#   sh SCRIPTS/validate-maven-modules.sh
#       檢查所有 Maven 子模組是否已宣告於專案根目錄的 pom.xml。
#       若有缺漏則回傳 exit code 1，適合用於 CI 驗證。
#
#   sh SCRIPTS/validate-maven-modules.sh --checkLost
#       列出尚未宣告於根 pom.xml 的 Maven 子模組；有缺漏時回傳 exit code 1。
#
#   sh SCRIPTS/validate-maven-modules.sh --fix
#       自動將缺漏的 Maven 子模組補入根 pom.xml；若根 pom.xml 不存在則建立聚合 POM。
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

  no option     Check whether every Maven submodule is declared in the root pom.xml.
  --checkLost   List Maven submodules missing from the root pom.xml.
  --fix         Add missing Maven submodules to the root pom.xml.
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
MISSING="$WORK_DIR/missing"

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

find_missing_modules() {
    read_declared_modules
    awk 'FILENAME == ARGV[1] { declared[$0] = 1; next } !($0 in declared)' "$DECLARED" "$DISCOVERED" > "$MISSING"
}

missing_count() {
    awk 'END { print NR + 0 }' "$MISSING"
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
    done < "$MISSING"

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

find_missing_modules
COUNT=$(missing_count)

case "$MODE" in
    check)
        if [ ! -f "$ROOT_POM" ]; then
            printf 'ERROR: Root pom.xml does not exist. Run with --checkLost or --fix.\n' >&2
            exit 1
        fi
        if [ "$COUNT" -ne 0 ]; then
            printf 'ERROR: %s Maven submodule(s) are missing from pom.xml. Run with --checkLost for details.\n' "$COUNT" >&2
            exit 1
        fi
        printf 'OK: All Maven submodules are declared in pom.xml.\n'
        ;;
    list)
        if [ "$COUNT" -eq 0 ]; then
            printf 'No missing Maven submodules.\n'
            exit 0
        fi
        printf 'Missing Maven submodules (%s):\n' "$COUNT"
        sed 's/^/  - /' "$MISSING"
        exit 1
        ;;
    fix)
        if [ "$COUNT" -eq 0 ]; then
            printf 'No missing Maven submodules; pom.xml was not changed.\n'
            exit 0
        fi
        if [ ! -f "$ROOT_POM" ]; then
            create_root_pom
        fi
        add_missing_modules
        printf 'Added %s Maven submodule(s) to pom.xml:\n' "$COUNT"
        sed 's/^/  - /' "$MISSING"
        ;;
esac
