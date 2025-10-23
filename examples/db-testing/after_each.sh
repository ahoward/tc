#!/usr/bin/env bash
# after_each.sh - Cleanup test data after each scenario

set -e

# DB_FILE is loaded from tc-env by tc framework
DB_FILE="${DB_FILE:-$TC_SUITE_PATH/test.db}"

# Clear all data (but keep schema)
echo "Cleaning up data for scenario: $TC_SCENARIO" >&2
sqlite3 "$DB_FILE" <<EOF
DELETE FROM posts;
DELETE FROM users;
DELETE FROM sqlite_sequence WHERE name IN ('users', 'posts');
EOF
