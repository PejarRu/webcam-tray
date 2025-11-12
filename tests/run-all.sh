#!/bin/bash
# VirtualCam Tray - Master Test Runner
# Executes all test suites

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_PASSED=0
TOTAL_FAILED=0

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  VirtualCam Tray - Test Suite Runner  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Parse arguments
RUN_UNIT=true
RUN_SMOKE=true
RUN_CHAOS=true
RUN_PERFORMANCE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --unit-only)
            RUN_SMOKE=false
            RUN_CHAOS=false
            RUN_PERFORMANCE=false
            shift
            ;;
        --smoke-only)
            RUN_UNIT=false
            RUN_CHAOS=false
            RUN_PERFORMANCE=false
            shift
            ;;
        --chaos-only)
            RUN_UNIT=false
            RUN_SMOKE=false
            RUN_PERFORMANCE=false
            shift
            ;;
        --performance-only)
            RUN_UNIT=false
            RUN_SMOKE=false
            RUN_CHAOS=false
            shift
            ;;
        --no-unit)
            RUN_UNIT=false
            shift
            ;;
        --no-smoke)
            RUN_SMOKE=false
            shift
            ;;
        --no-chaos)
            RUN_CHAOS=false
            shift
            ;;
        --no-performance)
            RUN_PERFORMANCE=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --unit-only        Run only unit tests (bats)"
            echo "  --smoke-only       Run only smoke tests"
            echo "  --chaos-only       Run only chaos tests"
            echo "  --performance-only Run only performance tests"
            echo "  --no-unit          Skip unit tests"
            echo "  --no-smoke         Skip smoke tests"
            echo "  --no-chaos         Skip chaos tests"
            echo "  --no-performance   Skip performance tests"
            echo "  --help, -h         Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Helper function to run a test suite
run_test_suite() {
    local name="$1"
    local script="$2"
    
    echo -e "${BLUE}▶ Running: $name${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ ! -f "$script" ]; then
        echo -e "${YELLOW}⚠ Test script not found: $script${NC}"
        echo ""
        return 1
    fi
    
    if ! [ -x "$script" ]; then
        chmod +x "$script"
    fi
    
    if "$script"; then
        echo -e "${GREEN}✅ $name: PASSED${NC}"
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
        echo ""
        return 0
    else
        echo -e "${RED}❌ $name: FAILED${NC}"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        echo ""
        return 1
    fi
}

# Run test suites
START_TIME=$(date +%s)

if $RUN_UNIT; then
    if command -v bats &> /dev/null; then
        echo -e "${BLUE}▶ Running: Unit Tests (bats)${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        if bats "$SCRIPT_DIR"/*.bats; then
            echo -e "${GREEN}✅ Unit Tests: PASSED${NC}"
            TOTAL_PASSED=$((TOTAL_PASSED + 1))
        else
            echo -e "${RED}❌ Unit Tests: FAILED${NC}"
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
        fi
        echo ""
    else
        echo -e "${YELLOW}⚠ bats not installed, skipping unit tests${NC}"
        echo "  Install: sudo pacman -S bats (Arch) or sudo apt install bats (Ubuntu)"
        echo ""
    fi
fi

if $RUN_SMOKE; then
    run_test_suite "Smoke Tests" "$SCRIPT_DIR/smoke-test.sh" || true
fi

if $RUN_CHAOS; then
    run_test_suite "Chaos Tests" "$SCRIPT_DIR/chaos-test.sh" || true
fi

if $RUN_PERFORMANCE; then
    run_test_suite "Performance Tests" "$SCRIPT_DIR/performance-test.sh" || true
fi

# Summary
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Test Summary                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Total Suites Run:    $((TOTAL_PASSED + TOTAL_FAILED))"
echo -e "  ${GREEN}Passed:              $TOTAL_PASSED${NC}"
echo -e "  ${RED}Failed:              $TOTAL_FAILED${NC}"
echo -e "  Elapsed Time:        ${ELAPSED}s"
echo ""

if [ $TOTAL_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ ALL TESTS PASSED! 🎉            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ SOME TESTS FAILED                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    exit 1
fi
