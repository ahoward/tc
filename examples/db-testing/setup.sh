#!/usr/bin/env bash
# setup.sh - Create test database (runs once before all tests)

set -e

# Create a temporary test database
DB_FILE="$TC_SUITE_PATH/test.db"

# Remove old DB if exists
rm -f "$DB_FILE"

# Create schema
sqlite3 "$DB_FILE" <<EOF
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
EOF

# Store DB path in tc-env for other hooks to use
echo "export DB_FILE=\"$DB_FILE\"" > "$TC_SUITE_PATH/tc-env"

echo "Test database created: $DB_FILE" >&2
