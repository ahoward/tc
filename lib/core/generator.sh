#!/usr/bin/env bash
# tc test suite generator
# building test scaffolds with theodore 🚁

source "$(dirname "${BASH_SOURCE[0]}")/../utils/log.sh"

# T008: validate test name follows unix conventions
tc_validate_test_name() {
    local test_name="$1"

    # regex: ^[a-z0-9][a-z0-9-]*[a-z0-9]$
    # - start with lowercase letter or digit
    # - middle can contain hyphens
    # - end with lowercase letter or digit
    # - minimum 2 characters (start + end)

    if [ -z "$test_name" ]; then
        tc_error "Test name cannot be empty"
        return 1
    fi

    # check if matches pattern
    if ! echo "$test_name" | grep -qE '^[a-z0-9][a-z0-9-]*[a-z0-9]$'; then
        # special case: single character names (just a-z0-9)
        if echo "$test_name" | grep -qE '^[a-z0-9]$'; then
            return 0
        fi

        tc_error "Invalid test name: $test_name"
        tc_error "Test names must:"
        tc_error "  - use only lowercase letters, numbers, and hyphens"
        tc_error "  - start and end with a letter or number"
        tc_error "  - not start or end with a hyphen"
        tc_error ""
        tc_error "Examples: 'my-test', 'user-login', 'api-v2'"
        return 1
    fi

    return 0
}

# T009: parse test path and extract components
tc_parse_test_path() {
    local test_path="$1"

    # validate non-empty
    if [ -z "$test_path" ]; then
        tc_error "Test path cannot be empty"
        return 1
    fi

    # extract components
    local test_name=$(basename "$test_path")
    local parent_dir=$(dirname "$test_path")

    # derive run_when from path segments
    # e.g., "tests/auth/login" -> "testing auth"
    local run_when="testing"
    if [ "$parent_dir" != "." ] && [ "$parent_dir" != "/" ]; then
        # extract meaningful path segments (skip common prefixes like "tests")
        local segments=$(echo "$parent_dir" | tr '/' '\n' | grep -v '^tests$' | grep -v '^\.$' | head -1)
        if [ -n "$segments" ]; then
            run_when="testing $segments"
        fi
    fi

    # output as key=value pairs
    echo "test_name=$test_name"
    echo "parent_dir=$parent_dir"
    echo "run_when=$run_when"
}

# T010: check if path exists and handle conflicts
tc_check_path_exists() {
    local test_path="$1"
    local force="${2:-false}"

    if [ -e "$test_path" ]; then
        if [ "$force" != "true" ]; then
            tc_error "Directory already exists: $test_path"
            tc_error "Use --force to overwrite"
            return 1
        else
            tc_warn "Overwriting existing directory: $test_path"
        fi
    fi

    return 0
}

# T011: create directory structure with validation
tc_create_directory_structure() {
    local test_path="$1"

    # create parent directories if needed
    local parent_dir=$(dirname "$test_path")
    if [ ! -d "$parent_dir" ]; then
        if ! mkdir -p "$parent_dir" 2>/dev/null; then
            tc_error "Cannot create parent directory: $parent_dir"
            tc_error "Check permissions"
            return 1
        fi
    fi

    # create test directory
    if ! mkdir -p "$test_path" 2>/dev/null; then
        tc_error "Cannot create test directory: $test_path"
        tc_error "Check permissions"
        return 1
    fi

    # create data directory
    if ! mkdir -p "$test_path/data/example-scenario" 2>/dev/null; then
        tc_error "Cannot create data directory: $test_path/data"
        return 1
    fi

    tc_debug "Created directory structure: $test_path"
    return 0
}

# T012: set executable permission on run script
tc_set_executable_permission() {
    local run_script="$1"

    if [ ! -f "$run_script" ]; then
        tc_error "Run script not found: $run_script"
        return 1
    fi

    if ! chmod +x "$run_script" 2>/dev/null; then
        tc_error "Cannot make run script executable: $run_script"
        tc_error "Check permissions"
        return 1
    fi

    tc_debug "Made executable: $run_script"
    return 0
}

# T021: parse optional flags from command line
tc_parse_optional_flags() {
    # expects global variables: TC_GEN_TAGS, TC_GEN_PRIORITY, TC_GEN_DESCRIPTION, TC_GEN_DEPENDS
    # these are set by tc_new_command before calling generation functions

    # set defaults if not provided
    TC_GEN_TAGS="${TC_GEN_TAGS:-}"
    TC_GEN_PRIORITY="${TC_GEN_PRIORITY:-medium}"
    TC_GEN_DESCRIPTION="${TC_GEN_DESCRIPTION:-TODO: describe test purpose}"
    TC_GEN_DEPENDS="${TC_GEN_DEPENDS:-}"
}

# T022: format tags for README (comma-separated to backtick-wrapped)
tc_format_tags_for_readme() {
    local tags="$1"

    if [ -z "$tags" ]; then
        echo ""
        return
    fi

    # convert "tag1,tag2,tag3" to ", `tag1`, `tag2`, `tag3`"
    local formatted=""
    IFS=',' read -ra tag_array <<< "$tags"
    for tag in "${tag_array[@]}"; do
        # trim whitespace
        tag=$(echo "$tag" | xargs)
        if [ -n "$tag" ]; then
            formatted="$formatted, \`$tag\`"
        fi
    done

    echo "$formatted"
}

# T023: build template variables with defaults
tc_build_template_variables() {
    local test_path="$1"

    # parse path info
    local path_info=$(tc_parse_test_path "$test_path")
    local test_name=$(echo "$path_info" | grep '^test_name=' | cut -d= -f2-)
    local run_when=$(echo "$path_info" | grep '^run_when=' | cut -d= -f2-)

    # parse optional flags (sets defaults if not provided)
    tc_parse_optional_flags

    # format tags for README
    local extra_tags=$(tc_format_tags_for_readme "$TC_GEN_TAGS")

    # export variables for use by generation functions
    export TC_VAR_TEST_NAME="$test_name"
    export TC_VAR_TEST_PATH="$test_path"
    export TC_VAR_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    export TC_VAR_DESCRIPTION="$TC_GEN_DESCRIPTION"
    export TC_VAR_EXTRA_TAGS="$extra_tags"
    export TC_VAR_DEPENDENCIES="$TC_GEN_DEPENDS"
    export TC_VAR_PRIORITY="$TC_GEN_PRIORITY"
    export TC_VAR_RUN_WHEN="$run_when"
}

# T013: generate from template (main generation orchestrator)
tc_generate_from_template() {
    local test_path="$1"
    local template_dir="${2:-default}"

    # resolve absolute paths
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local templates_root="$script_dir/../templates"

    # for now, only support "default" template (US3 will add more)
    if [ "$template_dir" != "default" ]; then
        tc_warn "Template '$template_dir' not yet supported, using 'default'"
        template_dir="default"
    fi

    local template_path="$templates_root/$template_dir"

    if [ ! -d "$template_path" ]; then
        tc_error "Template not found: $template_path"
        return 1
    fi

    # build template variables (T023)
    tc_build_template_variables "$test_path"

    # generate all files
    tc_generate_run_script "$test_path" "$template_path" || return 1
    tc_generate_readme "$test_path" "$template_path" || return 1
    tc_generate_data_files "$test_path" "$template_path" || return 1

    return 0
}

# T014: variable substitution helpers
_tc_substitute_variables() {
    local content="$1"
    local test_name="$2"
    local test_path="$3"
    local timestamp="$4"
    local description="${5:-TODO: describe test purpose}"
    local extra_tags="${6:-}"
    local dependencies="${7:-}"
    local priority="${8:-medium}"
    local run_when="${9:-testing}"

    # perform variable substitution
    content="${content//\$\{TEST_NAME\}/$test_name}"
    content="${content//\$\{TEST_PATH\}/$test_path}"
    content="${content//\$\{TIMESTAMP\}/$timestamp}"
    content="${content//\$\{DESCRIPTION\}/$description}"
    content="${content//\$\{EXTRA_TAGS\}/$extra_tags}"
    content="${content//\$\{DEPENDENCIES\}/$dependencies}"
    content="${content//\$\{PRIORITY\}/$priority}"
    content="${content//\$\{RUN_WHEN\}/$run_when}"

    echo "$content"
}

# T015: generate run script from template
tc_generate_run_script() {
    local test_path="$1"
    local template_path="$2"
    local run_template="$template_path/run.template"

    if [ ! -f "$run_template" ]; then
        tc_error "Run template not found: $run_template"
        return 1
    fi

    # read template
    local template_content=$(cat "$run_template")

    # use exported variables from tc_build_template_variables
    local output=$(_tc_substitute_variables "$template_content" \
        "$TC_VAR_TEST_NAME" "$TC_VAR_TEST_PATH" "$TC_VAR_TIMESTAMP" \
        "$TC_VAR_DESCRIPTION" "$TC_VAR_EXTRA_TAGS" "$TC_VAR_DEPENDENCIES" \
        "$TC_VAR_PRIORITY" "$TC_VAR_RUN_WHEN")

    # write run script
    local run_script="$test_path/run"
    echo "$output" > "$run_script" || return 1

    # make executable
    tc_set_executable_permission "$run_script" || return 1

    tc_debug "Generated run script: $run_script"
    return 0
}

# T016/T024: generate README with custom metadata
tc_generate_readme() {
    local test_path="$1"
    local template_path="$2"
    local readme_template="$template_path/README.template"

    if [ ! -f "$readme_template" ]; then
        tc_error "README template not found: $readme_template"
        return 1
    fi

    # read template
    local template_content=$(cat "$readme_template")

    # use exported variables from tc_build_template_variables (includes custom metadata)
    local output=$(_tc_substitute_variables "$template_content" \
        "$TC_VAR_TEST_NAME" "$TC_VAR_TEST_PATH" "$TC_VAR_TIMESTAMP" \
        "$TC_VAR_DESCRIPTION" "$TC_VAR_EXTRA_TAGS" "$TC_VAR_DEPENDENCIES" \
        "$TC_VAR_PRIORITY" "$TC_VAR_RUN_WHEN")

    # write README
    local readme="$test_path/README.md"
    echo "$output" > "$readme" || return 1

    tc_debug "Generated README: $readme"
    return 0
}

# T017: generate data files (input.json, expected.json)
tc_generate_data_files() {
    local test_path="$1"
    local template_path="$2"
    local input_template="$template_path/input.template"
    local expected_template="$template_path/expected.template"

    if [ ! -f "$input_template" ] || [ ! -f "$expected_template" ]; then
        tc_error "Data templates not found in: $template_path"
        return 1
    fi

    # data directory already created by tc_create_directory_structure
    local data_dir="$test_path/data/example-scenario"

    # copy template files (these are static JSON, no substitution needed)
    cp "$input_template" "$data_dir/input.json" || return 1
    cp "$expected_template" "$data_dir/expected.json" || return 1

    tc_debug "Generated data files in: $data_dir"
    return 0
}

# T018: display success message with tree view and next steps
tc_display_success_message() {
    local test_path="$1"

    echo ""
    echo "created test suite: $test_path 🚁"
    echo ""
    echo "structure:"
    echo "  $test_path/"
    echo "  ├── run"
    echo "  ├── README.md"
    echo "  └── data/"
    echo "      └── example-scenario/"
    echo "          ├── input.json"
    echo "          └── expected.json"
    echo ""
    echo "next steps:"
    echo "  1. Edit $test_path/run to add test logic"
    echo "  2. Update data/example-scenario/*.json with real test data"
    echo "  3. Run: tc run $test_path"
    echo ""
    echo "the test will fail until you implement it - that's the point! 🚁"
    echo ""
}

# tc init - initialize test directory with README
tc_init_directory() {
    local target_dir="${1:-.}"

    # resolve absolute path
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local template_path="$script_dir/../templates/init/README.template"

    if [ ! -f "$template_path" ]; then
        tc_error "Init template not found: $template_path"
        return 1
    fi

    # create target directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        if ! mkdir -p "$target_dir" 2>/dev/null; then
            tc_error "Cannot create directory: $target_dir"
            return 1
        fi
    fi

    local readme_path="$target_dir/README.md"

    # check if README already exists
    if [ -f "$readme_path" ]; then
        tc_warn "README.md already exists: $readme_path"
        tc_error "Remove it first or choose a different directory"
        return 1
    fi

    # read template
    local template_content=$(cat "$template_path")

    # generate timestamp
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # substitute variables
    template_content="${template_content//\$\{TIMESTAMP\}/$timestamp}"

    # write README
    echo "$template_content" > "$readme_path" || return 1

    # success message
    echo ""
    echo "initialized test directory: $target_dir 🚁"
    echo ""
    echo "created:"
    echo "  $readme_path"
    echo ""
    echo "next steps:"
    echo "  1. Review $readme_path for testing guidelines"
    echo "  2. Create your first test: tc new $target_dir/my-feature"
    echo "  3. Read the README for AI integration tips"
    echo ""

    return 0
}
