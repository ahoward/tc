#!/usr/bin/env bash
# teardown.sh - Cleanup test database (runs once after all tests)

set -e

# DB_FILE is loaded from tc-env by tc framework
DB_FILE="${DB_FILE:-$TC_SUITE_PATH/test.db}"

# Remove test database
if [ -f "$DB_FILE" ]; then
    rm -f "$DB_FILE"
    echo "Test database removed: $DB_FILE" >&2
fi

# Remove tc-env file
rm -f "$TC_SUITE_PATH/tc-env"

echo "Teardown complete" >&2
