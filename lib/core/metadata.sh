#!/usr/bin/env bash
# tc metadata extraction
# teaching the chopper to read 🚁

source "$(dirname "${BASH_SOURCE[0]}")/../utils/log.sh"

# extract metadata from suite README.md
tc_extract_metadata() {
    local suite_dir="$1"
    local readme="$suite_dir/README.md"

    if [ ! -f "$readme" ]; then
        return 1
    fi

    # extract tags
    local tags=$(grep -i '^\*\*tags\*\*:' "$readme" 2>/dev/null | \
        sed 's/.*: //; s/`//g; s/, */ /g')

    # extract what
    local what=$(grep -i '^\*\*what\*\*:' "$readme" 2>/dev/null | \
        sed 's/.*: //')

    # extract depends
    local depends=$(grep -i '^\*\*depends\*\*:' "$readme" 2>/dev/null | \
        sed 's/.*: //; s/, */ /g')

    # extract priority
    local priority=$(grep -i '^\*\*priority\*\*:' "$readme" 2>/dev/null | \
        sed 's/.*: //; s/ *$//')

    # extract related
    local related=$(grep -i '^\*\*related\*\*:' "$readme" 2>/dev/null | \
        sed 's/.*: //; s/, */ /g')

    # output as key=value pairs
    echo "tags=$tags"
    echo "what=$what"
    echo "depends=$depends"
    echo "priority=$priority"
    echo "related=$related"
}

# check if suite matches tags
tc_suite_has_tag() {
    local suite_dir="$1"
    local search_tag="$2"

    local metadata=$(tc_extract_metadata "$suite_dir")
    local tags=$(echo "$metadata" | grep '^tags=' | cut -d= -f2-)

    # check if search_tag is in tags
    echo "$tags" | grep -qw "$search_tag"
}

# check if suite matches priority
tc_suite_has_priority() {
    local suite_dir="$1"
    local search_priority="$2"

    local metadata=$(tc_extract_metadata "$suite_dir")
    local priority=$(echo "$metadata" | grep '^priority=' | cut -d= -f2-)

    [ "$priority" = "$search_priority" ]
}

# search suite description for query
tc_suite_matches_search() {
    local suite_dir="$1"
    local query="$2"
    local readme="$suite_dir/README.md"

    if [ ! -f "$readme" ]; then
        return 1
    fi

    # case-insensitive grep
    grep -qi "$query" "$readme"
}

# get suite tags
tc_get_suite_tags() {
    local suite_dir="$1"

    local metadata=$(tc_extract_metadata "$suite_dir")
    echo "$metadata" | grep '^tags=' | cut -d= -f2-
}

# get suite description
tc_get_suite_description() {
    local suite_dir="$1"

    local metadata=$(tc_extract_metadata "$suite_dir")
    echo "$metadata" | grep '^what=' | cut -d= -f2-
}

# list all tags in repository
tc_list_all_tags() {
    local root_path="${1:-.}"

    # discover all suites
    local suites=$(tc_discover_suites_recursive "$root_path")

    # extract all tags
    local all_tags=""
    while read -r suite_dir; do
        [ -z "$suite_dir" ] && continue
        local tags=$(tc_get_suite_tags "$suite_dir")
        all_tags="$all_tags $tags"
    done <<< "$suites"

    # unique sorted tags
    echo "$all_tags" | tr ' ' '\n' | sort -u | grep -v '^$'
}

# explain a test suite (AI-friendly)
tc_explain_suite() {
    local suite_dir="$1"
    local readme="$suite_dir/README.md"

    if [ ! -f "$readme" ]; then
        echo "No README.md found for: $suite_dir"
        return 1
    fi

    local metadata=$(tc_extract_metadata "$suite_dir")

    echo "Test Suite: $(basename "$suite_dir")"
    echo ""

    # show metadata
    while IFS='=' read -r key value; do
        if [ -n "$value" ]; then
            printf "%-12s %s\n" "$key:" "$value"
        fi
    done <<< "$metadata"

    echo ""

    # show description section
    if grep -q '^## description' "$readme"; then
        echo "Description:"
        sed -n '/^## description/,/^##/p' "$readme" | \
            grep -v '^##' | \
            sed 's/^/  /'
    fi
}
