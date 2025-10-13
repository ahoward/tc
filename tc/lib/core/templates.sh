#!/usr/bin/env bash
# tc template discovery and management
# finding templates like theodore finding the island 🚁

source "$(dirname "${BASH_SOURCE[0]}")/../utils/log.sh"

# T028: discover templates (built-in + examples)
tc_discover_templates() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local templates_root="$script_dir/../templates"
    local repo_root="$(cd "$script_dir/../.." && pwd)"
    local examples_dir="$repo_root/examples"

    # collect all templates
    local templates=()

    # discover built-in templates
    if [ -d "$templates_root" ]; then
        while IFS= read -r template_dir; do
            local name=$(basename "$template_dir")
            # skip init template (not for test generation)
            if [ "$name" != "init" ]; then
                templates+=("builtin:$name")
            fi
        done < <(find "$templates_root" -mindepth 1 -maxdepth 1 -type d)
    fi

    # discover example-based templates
    if [ -d "$examples_dir" ]; then
        while IFS= read -r example_dir; do
            local name=$(basename "$example_dir")
            # check if it's a valid test suite (has run script)
            if [ -x "$example_dir/run" ]; then
                templates+=("example:$name")
            fi
        done < <(find "$examples_dir" -mindepth 1 -maxdepth 1 -type d)
    fi

    # output templates (one per line, format: type:name)
    printf '%s\n' "${templates[@]}"
}

# T029: list templates with descriptions
tc_list_templates() {
    local templates=$(tc_discover_templates)

    echo "Available templates:"
    echo ""

    echo "Built-in templates:"
    while read -r template; do
        [ -z "$template" ] && continue
        if [[ "$template" == builtin:* ]]; then
            local name="${template#builtin:}"
            echo "  $name - Basic test suite structure"
        fi
    done <<< "$templates"

    echo ""
    echo "Example templates (from examples/):"
    local has_examples=false
    while read -r template; do
        [ -z "$template" ] && continue
        if [[ "$template" == example:* ]]; then
            has_examples=true
            local name="${template#example:}"
            echo "  $name - Based on examples/$name"
        fi
    done <<< "$templates"

    if [ "$has_examples" = false ]; then
        echo "  (no examples found)"
    fi

    echo ""
}

# T030: validate template exists
tc_validate_template_exists() {
    local template_name="$1"
    local templates=$(tc_discover_templates)

    # check if template exists in discovered templates
    while read -r template; do
        [ -z "$template" ] && continue
        if [[ "$template" == *:"$template_name" ]]; then
            return 0
        fi
    done <<< "$templates"

    tc_error "Template not found: $template_name"
    tc_error ""
    tc_error "Available templates:"
    tc_list_templates >&2
    return 1
}

# T031: load template files
tc_load_template_files() {
    local template_name="$1"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local templates_root="$script_dir/../templates"
    local repo_root="$(cd "$script_dir/../.." && pwd)"
    local examples_dir="$repo_root/examples"

    # determine template type and path
    local template_path=""
    local template_type=""

    # check built-in first
    if [ -d "$templates_root/$template_name" ]; then
        template_path="$templates_root/$template_name"
        template_type="builtin"
    # check examples
    elif [ -d "$examples_dir/$template_name" ]; then
        template_path="$examples_dir/$template_name"
        template_type="example"
    else
        tc_error "Template not found: $template_name"
        return 1
    fi

    # output template info
    echo "template_path=$template_path"
    echo "template_type=$template_type"
}
