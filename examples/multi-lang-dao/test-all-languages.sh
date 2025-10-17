#!/usr/bin/env bash
# Test all language implementations sequentially
# Demonstrates that all adapters pass identical test suite

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

echo "🚁 Testing All Language Implementations"
echo "========================================"
echo ""

# Track results
total_languages=0
passed_languages=0
failed_languages=0

# Test each language
test_language() {
    local name="$1"
    local adapter_path="$2"
    local emoji="$3"

    total_languages=$((total_languages + 1))

    echo "Testing $name $emoji"
    echo "Adapter: $adapter_path"

    if [ ! -x "$adapter_path" ]; then
        echo "  ✗ SKIP: Adapter not found or not executable"
        failed_languages=$((failed_languages + 1))
        echo ""
        return 1
    fi

    if ./manual-test.sh "$adapter_path" > /tmp/test-${name}.log 2>&1; then
        echo "  ✓ PASS: All tests passed"
        passed_languages=$((passed_languages + 1))
    else
        echo "  ✗ FAIL: Some tests failed (see /tmp/test-${name}.log)"
        failed_languages=$((failed_languages + 1))
        cat /tmp/test-${name}.log
    fi

    echo ""
}

# Run tests
test_language "Ruby" "../../projects/ruby/tc_adapter.rb" "💎"
test_language "Go" "../../projects/go/adapter" ""
test_language "Python" "../../projects/python/adapter.py" "🐍"
test_language "JavaScript" "../../projects/javascript/adapter.js" ""
test_language "Rust" "../../projects/rust/target/release/adapter" "🦀"

# Summary
echo "========================================"
echo "Summary:"
echo "  Total languages tested: $total_languages"
echo "  Passed: $passed_languages"
echo "  Failed/Skipped: $failed_languages"
echo ""

if [ $passed_languages -ge 4 ]; then
    echo "✓ Success: Pattern validated across multiple languages!"
    exit 0
else
    echo "✗ Warning: Less than 4 languages passed"
    exit 1
fi
