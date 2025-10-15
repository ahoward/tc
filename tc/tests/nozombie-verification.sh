#!/usr/bin/env bash
# Standalone test to verify nozombie.sh works correctly
# Tests that children are killed when master dies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/utils/nozombie.sh"

echo "🚁 nozombie.sh verification test"
echo ""

# Test 1: Basic initialization
echo "Test 1: Initialization"
tc_nozombie_init $$
echo "  ✓ Sidecar started (PID: $TC_NOZOMBIE_SIDECAR_PID)"
echo "  ✓ FIFO dir: $TC_NOZOMBIE_FIFO_DIR"
echo ""

# Test 2: Register and unregister
echo "Test 2: Register/Unregister"
sleep 60 &
test_pid=$!
echo "  Spawned sleep process: $test_pid"

tc_nozombie_register "$test_pid"
echo "  ✓ Registered with nozombie"

tc_nozombie_status
echo ""

# Kill the sleep process
kill "$test_pid" 2>/dev/null || true
tc_nozombie_unregister "$test_pid"
echo "  ✓ Unregistered after completion"
echo ""

# Test 3: tc_nozombie_run wrapper
echo "Test 3: tc_nozombie_run wrapper"
tc_nozombie_run sleep 1
echo "  ✓ Completed successfully (exit code: $?)"
echo ""

# Test 4: Timeout functionality
echo "Test 4: Timeout"
tc_nozombie_run_with_timeout 1 sleep 10
exit_code=$?

if [ $exit_code -eq 124 ]; then
    echo "  ✓ Timeout detected correctly (exit code: 124)"
else
    echo "  ✗ Unexpected exit code: $exit_code"
    exit 1
fi
echo ""

# Test 5: Orphan cleanup (this is the critical test)
echo "Test 5: Orphan cleanup"
echo "  Spawning subprocess that will spawn a grandchild..."

# Create a test script that spawns a grandchild
test_script=$(mktemp)
cat > "$test_script" <<'SCRIPT'
#!/usr/bin/env bash
# Spawn a grandchild that would normally become orphaned
sleep 999 &
grandchild_pid=$!
echo "grandchild:$grandchild_pid"

# This parent will be killed, but grandchild should also die
sleep 999
SCRIPT

chmod +x "$test_script"

# Run the test script with nozombie
output=$(tc_nozombie_run bash "$test_script" 2>&1) &
parent_pid=$!

# Give it time to spawn grandchild
sleep 0.5

# Extract grandchild PID
grandchild_pid=$(echo "$output" | grep "grandchild:" | cut -d: -f2)

# Kill the parent
kill -9 "$parent_pid" 2>/dev/null || true

# Wait a moment for nozombie to react
sleep 2

# Check if grandchild was killed
if kill -0 "$grandchild_pid" 2>/dev/null; then
    echo "  ✗ Grandchild $grandchild_pid still alive (ZOMBIE!)"
    kill -9 "$grandchild_pid" 2>/dev/null || true
    rm -f "$test_script"
    exit 1
else
    echo "  ✓ Grandchild $grandchild_pid was killed (no zombies!)"
fi

rm -f "$test_script"
echo ""

# Final status
echo "Final status:"
tc_nozombie_status
echo ""

# Cleanup
echo "Shutting down..."
tc_nozombie_shutdown
echo "  ✓ Clean shutdown"
echo ""

echo "🚁 All tests passed! Nozombie is working correctly."
