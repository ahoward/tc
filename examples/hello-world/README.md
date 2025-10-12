# hello-world - your first tc test suite 🚁

the simplest possible test suite: add two numbers.

## what's here

```
hello-world/
├── run                    # bash script that adds two numbers
└── data/
    ├── add-positive/      # 2 + 3 = 5
    ├── add-negative/      # -5 + 3 = -2
    └── add-zero/          # 0 + 0 = 0
```

## the runner

the `run` script:
1. reads input.json (expects fields `a` and `b`)
2. adds them together
3. outputs result as json: `{"result": sum}`

## running it

```bash
tc run examples/hello-world
```

expected output:

```
tc test results
================
suite: hello-world

  ✓ add-negative (18ms)
  ✓ add-positive (22ms)
  ✓ add-zero (15ms)

summary: 3 passed, 0 failed, 0 errors (3 total)
```

## learning from this example

1. **minimal structure**: just a `run` script and some data files
2. **json i/o**: input.json goes in, json comes out
3. **multiple scenarios**: add-positive, add-negative, add-zero all test different cases
4. **semantic comparison**: tc compares json intelligently

## modify it

try adding a failing test:

```bash
mkdir examples/hello-world/data/bad-math
echo '{"a": 2, "b": 2}' > examples/hello-world/data/bad-math/input.json
echo '{"result": 5}' > examples/hello-world/data/bad-math/expected.json  # wrong!
tc run examples/hello-world
```

you'll see:

```
  ✗ bad-math (18ms)
    diff:
      expected: 5
      got: 4
```

## next steps

- check out the main docs/readme.md
- write your own test suite
- try a different language for the runner (python, go, rust...)

🚁 **keep it simple, keep it flying**
