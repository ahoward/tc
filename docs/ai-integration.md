# ai integration - teaching the chopper to read minds 🚁

tc is designed to be AI-friendly. tests should be discoverable, understandable, and runnable by AI assistants like claude, gemini, or copilot.

## test metadata format

every test suite should have a `README.md` with structured frontmatter:

```markdown
# test-name

**tags**: `auth`, `login`, `security`, `integration`
**what**: tests user authentication flow from login to session creation
**depends**: database, user-service
**related**: logout-tests, session-tests
**priority**: high

## description

tests the complete authentication workflow including:
- valid credentials → successful login
- invalid credentials → error handling
- session token generation
- token validation

## scenarios

- `happy-path` - valid user logs in successfully
- `invalid-password` - login fails with wrong password
- `unknown-user` - login fails for non-existent user
- `expired-token` - session expires after timeout
```

### structured fields

- **tags**: comma-separated keywords for filtering (`auth`, `api`, `database`, `integration`, `unit`)
- **what**: single sentence describing what this tests (for AI understanding)
- **depends**: prerequisites that must pass first
- **related**: other relevant test suites
- **priority**: `high`, `medium`, `low` (helps AI prioritize)

## ai-friendly commands

### natural language queries

with structured metadata, AIs can:

```bash
# "run all auth tests"
tc run tests --tags auth

# "run high priority tests"
tc run tests --priority high

# "run tests related to authentication"
tc run tests --search "authentication"

# "what tests are failing?"
tc status --failed

# "show me tests that depend on database"
tc list --depends database
```

### metadata discovery

```bash
# list all tags
tc tags

# show tests by tag
tc list --tags auth

# find tests by description
tc search "authentication flow"

# show test dependencies
tc deps tests/auth/login
```

## .tc-meta.json - machine-readable metadata

for deeper AI integration, suites can include `.tc-meta.json`:

```json
{
  "name": "auth-login",
  "description": "Tests user authentication flow",
  "tags": ["auth", "login", "security", "integration"],
  "what": "validates username/password authentication and session creation",
  "depends_on": ["database-connection", "user-service"],
  "related": ["auth-logout", "session-management"],
  "priority": "high",
  "scenarios": {
    "happy-path": {
      "description": "valid user logs in successfully",
      "expects": "200 OK with session token"
    },
    "invalid-password": {
      "description": "login fails with wrong password",
      "expects": "401 Unauthorized"
    }
  },
  "ai_hints": {
    "run_when": "testing authentication or login functionality",
    "skip_when": "database is unavailable",
    "related_features": ["session management", "password validation", "user accounts"]
  }
}
```

## README.md parsing

tc should extract metadata from README frontmatter:

```markdown
# auth-login

**tags**: `auth`, `login`, `security`
**what**: tests user login with username and password
**depends**: database, user-service
**priority**: high
```

parsed as:
```json
{
  "tags": ["auth", "login", "security"],
  "what": "tests user login with username and password",
  "depends": ["database", "user-service"],
  "priority": "high"
}
```

## ai interaction patterns

### conversational test running

**human**: "run all the auth tests"
**ai**: *parses "auth" → searches tags → finds matches*
```bash
tc run tests --tags auth
```

**human**: "what failed?"
**ai**: *checks exit codes and .tc-result files*
```bash
tc status --failed
# shows: auth-login (2 scenarios failed)
```

**human**: "why did auth-login fail?"
**ai**: *reads .tc-result, compares expected vs actual*
```
Scenario 'invalid-password' failed:
  Expected: 401 Unauthorized
  Got: 500 Internal Server Error
  Suggests: check error handling in auth middleware
```

### test discovery by intent

**human**: "i'm working on session management, what should i test?"
**ai**: *searches metadata for "session"*
```
Found 3 related test suites:
- auth-login (creates sessions)
- session-timeout (validates expiry)
- session-refresh (token renewal)

Recommend running: tc run tests --tags session
```

## implementation phases

### phase 1: metadata extraction
- parse README.md frontmatter
- extract **tags**, **what**, **depends**, **priority**
- store in memory during test discovery

### phase 2: filtering flags
- `--tags <tag>` - filter by tags
- `--priority <level>` - filter by priority
- `--search <query>` - fuzzy search in descriptions
- `--depends <dep>` - find tests needing dependency

### phase 3: ai-friendly status
- `tc status` - show suite health
- `tc status --failed` - only failures
- `tc status --tags auth` - filtered status
- json output for AI parsing: `tc status --json`

### phase 4: natural language layer
- `tc ask "what tests cover auth?"` - LLM-powered query
- `tc explain auth-login` - describe what test does
- `tc suggest` - recommend tests based on recent changes

## example: ai-readable test suite

```
tests/api/auth/login/
├── README.md                    # human + AI readable
├── .tc-meta.json               # machine-readable (optional)
├── run                         # test runner
└── data/
    ├── valid-login/
    ├── invalid-password/
    └── unknown-user/
```

**README.md:**
```markdown
# login authentication

**tags**: `auth`, `api`, `login`, `security`, `integration`
**what**: validates user login endpoint with various credentials
**depends**: user-database, auth-service
**related**: logout, session-management, password-reset
**priority**: high

## description

tests the POST /auth/login endpoint for:
- successful authentication with valid credentials
- proper error handling for invalid passwords
- user-not-found scenarios
- session token generation and validation

critical for: authentication flows, security testing, api validation

## scenarios

- `valid-login` - user logs in with correct username/password → 200 OK + token
- `invalid-password` - wrong password → 401 Unauthorized
- `unknown-user` - non-existent user → 404 Not Found

## ai notes

run this when: testing auth, working on login, debugging authentication
skip this when: database unavailable, auth service down
after this: run session-management, token-validation tests
```

## benefits for AI assistants

1. **context understanding**: AI knows what each test does
2. **smart filtering**: "run auth tests" → automatic tag matching
3. **dependency awareness**: knows test order and prerequisites
4. **failure analysis**: can explain why tests fail
5. **recommendation**: suggests related tests to run
6. **natural language**: speak to tc in plain english

## cli examples

```bash
# ai-friendly commands
tc run tests --tags auth                    # by tag
tc run tests --priority high                # by priority
tc run tests --search "authentication"      # by description
tc list --tags api,integration              # show matching tests
tc status --failed --json                   # machine-readable failures
tc explain tests/auth/login                 # describe test suite
tc suggest --changed src/auth               # recommend tests for changes

# traditional commands still work
tc run tests --all
tc run tests/auth/login
```

## json output format

for AI parsing:

```bash
tc status --json
```

```json
{
  "summary": {
    "total_suites": 12,
    "passed": 10,
    "failed": 2,
    "errors": 0
  },
  "suites": [
    {
      "path": "tests/auth/login",
      "name": "login",
      "status": "failed",
      "passed": 2,
      "failed": 1,
      "tags": ["auth", "api", "login"],
      "priority": "high",
      "failures": [
        {
          "scenario": "invalid-password",
          "expected": "401 Unauthorized",
          "actual": "500 Internal Server Error",
          "suggestion": "check error handling in auth middleware"
        }
      ]
    }
  ]
}
```

## future: LLM integration

```bash
# natural language test interface
tc ai "run all the authentication tests"
tc ai "what failed and why?"
tc ai "which tests should i run after changing the login endpoint?"
tc ai "explain what the auth tests do"
```

powered by:
- metadata extraction from README.md
- test result analysis from .tc-result files
- code change detection (git diff)
- LLM reasoning over test descriptions

## guidelines for test authors

to make tests AI-friendly:

1. **always include README.md** with tags and description
2. **use clear, descriptive tags**: `auth`, `api`, `database`, not `test1`, `misc`
3. **write human-readable scenario names**: `valid-login`, not `tc001`
4. **document dependencies**: list what must work first
5. **explain in plain english**: AIs read descriptions, not just code
6. **add AI hints**: "run when...", "skip when...", "after this..."

## implementation notes

### parsing README frontmatter

```bash
# extract metadata from README.md
tc_parse_readme() {
    local readme="$1"

    # extract **tags**: `tag1`, `tag2`
    tags=$(grep '^\*\*tags\*\*:' "$readme" | sed 's/.*: //; s/`//g')

    # extract **what**: description
    what=$(grep '^\*\*what\*\*:' "$readme" | sed 's/.*: //')

    # build json
    jq -n \
        --arg tags "$tags" \
        --arg what "$what" \
        '{tags: ($tags | split(", ")), what: $what}'
}
```

### tag-based filtering

```bash
tc run tests --tags auth
# discover suites → filter by tag → run matches
```

### json status output

```bash
tc status --json
# aggregate .tc-result files → format as json
```

## conclusion

with structured metadata and AI-friendly commands, tc becomes:
- **conversational**: "run auth tests" just works
- **discoverable**: AIs understand what tests do
- **explainable**: failures come with context
- **intelligent**: suggests tests based on changes

🚁 **the chopper now speaks AI**
