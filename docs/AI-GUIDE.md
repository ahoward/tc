# AI Assistant Guide for tc 🚁🤖

*quick reference for claude, gemini, copilot, and other AI assistants*

## how AIs should use tc

### understanding test intent

when user says: **"run all the auth tests"**

you should:
```bash
# 1. discover what tags exist
tc tags tests

# 2. if 'auth' tag exists, run it
tc run tests --tags auth

# 3. if no 'auth' tag, search descriptions
tc list tests | grep -i auth
```

### discovering available tests

```bash
# show all test suites with metadata
tc list tests

# Output:
#   integration/hierarchical       [integration discovery hierarchical all-flag]
#     tests tc's hierarchical test discovery with --all flag
#
#   integration/single-suite       [integration end-to-end execution core]
#     tests tc's ability to execute a complete test suite end-to-end

# show all available tags
tc tags tests

# Output:
#   auth
#   api
#   database
#   integration
#   unit
```

### running tests by intent

| user request | tc command |
|--------------|------------|
| "run auth tests" | `tc run tests --tags auth` |
| "run all integration tests" | `tc run tests --tags integration` |
| "run unit tests" | `tc run tests --tags unit` |
| "run all tests" | `tc run tests --all` |
| "test the login feature" | `tc run tests/auth/login` |

### explaining tests

```bash
# get detailed info about a test suite
tc explain tests/auth/login

# Output shows:
# - tags
# - what it tests
# - dependencies
# - priority
# - description
# - scenarios
```

### checking test results

```bash
# run tests
tc run tests --tags auth

# check exit code
if [ $? -eq 0 ]; then
    echo "all tests passed"
else
    echo "some tests failed"
fi

# parse .tc-result files for details
cat tests/auth/login/.tc-result | jq .
```

## ai workflow patterns

### pattern 1: user asks to run tests by category

**user**: "run all the database tests"

**ai reasoning**:
1. user mentioned "database" → this is likely a tag
2. check if database tag exists
3. run with tag filter

**ai actions**:
```bash
tc run tests --tags database
```

### pattern 2: user asks what failed

**user**: "what failed?"

**ai reasoning**:
1. need to find suites with failures
2. check .tc-result files
3. parse and explain

**ai actions**:
```bash
# find all .tc-result files
find tests -name '.tc-result' -exec cat {} \;

# or parse with jq
find tests -name '.tc-result' -exec jq -r 'select(.status == "fail") | "\(.suite)/\(.scenario): expected \(.expected), got \(.actual)"' {} \;
```

### pattern 3: user is working on a feature

**user**: "i'm working on authentication, what should i test?"

**ai reasoning**:
1. user mentioned "authentication"
2. find related tests
3. suggest running them

**ai actions**:
```bash
# find tests related to auth
tc list tests | grep -i auth

# suggest running them
tc run tests --tags auth
```

### pattern 4: user asks about test coverage

**user**: "what tests do we have for the api?"

**ai reasoning**:
1. list tests with "api" tag or mention
2. explain what they cover

**ai actions**:
```bash
# show tests with api tag
tc list tests | grep api

# or search by tag
tc tags tests | grep api
tc run tests --tags api --dry-run  # if dry-run supported
```

## parsing metadata programmatically

### extract tags from README

```bash
grep '^\*\*tags\*\*:' tests/auth/login/README.md | \
    sed 's/.*: //; s/`//g; s/, */ /g'
```

### extract description

```bash
grep '^\*\*what\*\*:' tests/auth/login/README.md | \
    sed 's/.*: //'
```

### check if suite has specific tag

```bash
if tc run tests/auth/login --tags auth 2>/dev/null; then
    echo "has auth tag"
fi
```

## natural language to tc mapping

| natural language | tc command | notes |
|------------------|------------|-------|
| "run auth tests" | `tc run tests --tags auth` | tag-based |
| "test login" | `tc run tests/auth/login` | path-based |
| "run all tests" | `tc run tests --all` | hierarchical |
| "what tests exist?" | `tc list tests` | discovery |
| "show me tags" | `tc tags tests` | metadata |
| "explain login tests" | `tc explain tests/auth/login` | documentation |
| "run integration tests" | `tc run tests --tags integration` | tag-based |

## metadata format (for understanding)

test suites should have README.md with:

```markdown
# suite-name

**tags**: `tag1`, `tag2`, `tag3`
**what**: single sentence describing what this tests
**depends**: prerequisite-1, prerequisite-2
**priority**: high|medium|low
**related**: other-suite-1, other-suite-2

## description
detailed explanation...

## scenarios
- scenario-1 - what it does
- scenario-2 - what it does
```

## best practices for AIs

1. **always check tags first**
   ```bash
   tc tags tests
   ```

2. **use tag filtering when user mentions categories**
   - "auth tests" → `--tags auth`
   - "api tests" → `--tags api`
   - "unit tests" → `--tags unit`

3. **explain what you're running**
   ```
   running auth tests with: tc run tests --tags auth
   ```

4. **parse results for user**
   - exit code 0 = all passed
   - exit code 1 = some failed
   - .tc-result files have details

5. **suggest related tests**
   ```bash
   # after running tests, suggest related
   tc list tests | grep -i "related-keyword"
   ```

## example ai interaction

**user**: "run all authentication tests"

**ai response**:
```
i'll run all tests tagged with 'auth':

$ tc tags tests
  auth
  api
  database
  integration
  unit

$ tc run tests --tags auth

running auth tests...

tc test results
================
suite: login

  ✓ valid-credentials (45ms)
  ✓ invalid-password (32ms)
  ✓ unknown-user (28ms)

summary: 3 passed, 0 failed, 0 errors (3 total)

====================================
overall results
====================================

suites run: 2
✓ all 5 tests passed

all authentication tests passed! ✓
```

## debugging failures (ai workflow)

when tests fail:

1. **show failure summary**
   ```bash
   tc run tests --tags auth
   # parse output for failures
   ```

2. **explain what failed**
   ```bash
   tc explain tests/auth/login
   # show what the test does
   ```

3. **show expected vs actual**
   ```bash
   cat tests/auth/login/.tc-result | \
       jq 'select(.status == "fail")'
   ```

4. **suggest fixes**
   - based on test description
   - based on expected/actual diff
   - based on error messages

## advanced: combining with grep

```bash
# find tests mentioning "password"
tc list tests | grep -i password

# find high priority tests
grep -r '^\*\*priority\*\*: high' tests --include="README.md" | \
    cut -d/ -f1-3 | sort -u

# find tests that depend on database
grep -r '^\*\*depends\*\*:.*database' tests --include="README.md"
```

## json output (future)

if tc supports --json flag:

```bash
# machine-readable output
tc list tests --json | jq '.[] | select(.tags | contains(["auth"]))'

# status as json
tc status --json | jq '.suites[] | select(.status == "failed")'
```

## conclusion

tc is AI-friendly because:
- **structured metadata**: tags, descriptions, priorities
- **natural language mapping**: "run auth tests" → `--tags auth`
- **discoverable**: `tc list`, `tc tags`, `tc explain`
- **parseable**: clean output, .tc-result files
- **intentional**: tests express what they do, not just how

AIs should:
- use tags for categorical queries
- use paths for specific suites
- explain what they're running
- parse results for users
- suggest related tests

🚁🤖 **the chopper and the ai, flying together**
