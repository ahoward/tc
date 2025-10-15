#!/usr/bin/env bash
# Manual test script for multi-language DAO implementations
# Validates that adapters work correctly (bypasses UUID matching issue)

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
adapter="${1:-../../projects/ruby/tc_adapter.rb}"

echo "Testing adapter: $adapter"
echo "================================"
echo ""

# Test 1: /prompt/generate
echo "Test 1: /prompt/generate"
result=$(cat data/prompt-generate/input.json | "$adapter")
echo "Result: $result"

id=$(echo "$result" | jq -r '.id')
status=$(echo "$result" | jq -r '.status')

if [[ "$status" == "pending" ]] && [[ "$id" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]]; then
    echo "✓ PASS: Returns pending status with valid UUID"
else
    echo "✗ FAIL: Expected pending status with UUID, got: $result"
    exit 1
fi
echo ""

# Test 2: /usage/track (synchronous)
echo "Test 2: /usage/track"
result=$(cat data/usage-track/input.json | "$adapter")
echo "Result: $result"

status=$(echo "$result" | jq -r '.status')
tracked=$(echo "$result" | jq -r '.result.tracked')

if [[ "$status" == "completed" ]] && [[ "$tracked" == "true" ]]; then
    echo "✓ PASS: Returns completed status with tracked=true"
else
    echo "✗ FAIL: Expected completed status with tracked=true, got: $result"
    exit 1
fi
echo ""

# Test 3: /template/create
echo "Test 3: /template/create"
result=$(cat data/template-create/input.json | "$adapter")
echo "Result: $result"

status=$(echo "$result" | jq -r '.status')

if [[ "$status" == "pending" ]]; then
    echo "✓ PASS: Returns pending status"
else
    echo "✗ FAIL: Expected pending status, got: $result"
    exit 1
fi
echo ""

# Test 4: /template/render
echo "Test 4: /template/render"
result=$(cat data/template-render/input.json | "$adapter")
echo "Result: $result"

status=$(echo "$result" | jq -r '.status')

if [[ "$status" == "pending" ]]; then
    echo "✓ PASS: Returns pending status"
else
    echo "✗ FAIL: Expected pending status, got: $result"
    exit 1
fi
echo ""

# Test 5: /result/poll (should return error for unknown ID)
echo "Test 5: /result/poll (unknown ID)"
result=$(cat data/result-poll/input.json | "$adapter")
echo "Result: $result"

error=$(echo "$result" | jq -r '.error // empty')

if [[ -n "$error" ]]; then
    echo "✓ PASS: Returns error for unknown ID"
else
    echo "✗ FAIL: Expected error, got: $result"
    exit 1
fi
echo ""

echo "================================"
echo "All manual tests passed! ✓"
echo ""
echo "Note: This validates adapter functionality."
echo "UUID pattern matching in tc is a known limitation."
