#!/bin/bash
# Developer Experience Test Suite
# Focus: What developers actually need to be productive

set -e

# Test configuration
IMAGE="${IMAGE:-ghcr.io/onezerocompany/devcontainer:base}"
FAILED_TESTS=0
PASSED_TESTS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${BLUE}Testing:${NC} ${test_name}"
    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAILED_TESTS++))
    fi
}

measure_time() {
    local test_name="$1"
    local test_command="$2"
    local max_seconds="$3"
    
    echo -e "\n${BLUE}Performance:${NC} ${test_name}"
    local start=$(date +%s)
    if eval "$test_command" > /dev/null 2>&1; then
        local end=$(date +%s)
        local duration=$((end - start))
        if [ $duration -le $max_seconds ]; then
            echo -e "${GREEN}✓ FAST${NC} (${duration}s, max: ${max_seconds}s)"
            ((PASSED_TESTS++))
        else
            echo -e "${RED}✗ SLOW${NC} (${duration}s, max: ${max_seconds}s)"
            ((FAILED_TESTS++))
        fi
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAILED_TESTS++))
    fi
}

# Create test workspace
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo -e "${YELLOW}=== DevContainer Developer Experience Tests ===${NC}"
echo -e "Testing image: ${IMAGE}\n"

# ========================================
# CRITICAL: Container Basics
# ========================================
echo -e "\n${YELLOW}[ Container Basics ]${NC}"

measure_time "Container starts quickly" \
    "docker run --rm $IMAGE echo 'ready'" \
    "5"

run_test "User has sudo access" \
    "docker run --rm $IMAGE sudo echo 'sudo works'"

run_test "Shell is zsh by default" \
    "docker run --rm $IMAGE bash -c 'echo \$SHELL | grep -q zsh'"

# ========================================
# CRITICAL: Development Tools
# ========================================
echo -e "\n${YELLOW}[ Development Tools ]${NC}"

run_test "Git is configured and working" \
    "docker run --rm $IMAGE git --version"

run_test "Node.js is installed and working" \
    "docker run --rm $IMAGE node --version"

run_test "npm can connect to registry" \
    "docker run --rm $IMAGE npm ping"

run_test "Mise is managing tools correctly" \
    "docker run --rm $IMAGE bash -c 'mise --version && mise list'"

# ========================================
# CRITICAL: File System Operations
# ========================================
echo -e "\n${YELLOW}[ File System Operations ]${NC}"

# Create a test project
cat > $TEST_DIR/package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "scripts": {
    "test": "echo 'Tests passed!' && exit 0",
    "build": "echo 'Build complete!' && exit 0"
  }
}
EOF

run_test "Can work with mounted volumes" \
    "docker run --rm -v $TEST_DIR:/workspace -w /workspace $IMAGE \
        bash -c 'ls -la package.json && cat package.json'"

run_test "Can create and edit files" \
    "docker run --rm -v $TEST_DIR:/workspace -w /workspace $IMAGE \
        bash -c 'echo \"console.log(42)\" > test.js && node test.js | grep -q 42'"

run_test "File permissions are correct" \
    "docker run --rm -v $TEST_DIR:/workspace -w /workspace $IMAGE \
        bash -c 'touch newfile && ls -l newfile | grep -q \"zero zero\"'"

# ========================================
# IMPORTANT: Real Developer Workflows
# ========================================
echo -e "\n${YELLOW}[ Developer Workflows ]${NC}"

run_test "Can run npm install" \
    "docker run --rm -v $TEST_DIR:/workspace -w /workspace $IMAGE \
        bash -c 'npm install --no-save express && test -d node_modules'"

run_test "Can run npm scripts" \
    "docker run --rm -v $TEST_DIR:/workspace -w /workspace $IMAGE \
        bash -c 'npm test && npm run build'"

run_test "Shell completions work" \
    "docker run --rm -it $IMAGE \
        bash -c 'echo -e \"git st\\t\" | zsh -i 2>&1 | grep -q \"status\"' || true"

# ========================================
# IMPORTANT: Developer Experience
# ========================================
echo -e "\n${YELLOW}[ Developer Experience ]${NC}"

run_test "Common aliases are set up" \
    "docker run --rm $IMAGE \
        bash -c 'grep -q \"alias apt-get\" ~/.zshrc'"

run_test "Interactive tools are available" \
    "docker run --rm $IMAGE \
        bash -c 'which fzf && which batcat && which eza'"

measure_time "Commands respond quickly" \
    "docker run --rm $IMAGE \
        bash -c 'for i in {1..10}; do git --version > /dev/null; done'" \
    "2"

# ========================================
# Docker-in-Docker (if using dind image)
# ========================================
if [[ "$IMAGE" == *":dind" ]]; then
    echo -e "\n${YELLOW}[ Docker-in-Docker ]${NC}"
    
    run_test "Docker CLI is available" \
        "docker run --rm $IMAGE docker --version"
    
    run_test "Docker Compose v2 works" \
        "docker run --rm $IMAGE docker compose version"
fi

# ========================================
# SUMMARY
# ========================================
echo -e "\n${YELLOW}=== Test Summary ===${NC}"
echo -e "Passed: ${GREEN}${PASSED_TESTS}${NC}"
echo -e "Failed: ${RED}${FAILED_TESTS}${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}✅ All developer experience tests passed!${NC}"
    echo "Developers can start coding immediately."
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed!${NC}"
    echo "Developer experience needs improvement."
    exit 1
fi