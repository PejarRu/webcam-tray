# webcam-tray Tests

Comprehensive test suite for webcam-tray with multiple testing strategies.

## 🧪 Test Types

### 1. Unit Tests (bats)
Basic functionality tests without hardware dependencies.

**Files**: `test_webcam-tray.bats`, `test_install.bats`

**Run**:
```bash
bats tests/
```

### 2. Smoke Tests
Quick validation that basic features work with real hardware.

**File**: `smoke-test.sh`

**What it tests**:
- Dependency verification
- v4l2loopback module loading
- Installation process
- Configuration file creation
- Autostart enable/disable
- Service file generation
- Service start/stop
- Video stream verification
- JSON logging

**Run**:
```bash
./tests/smoke-test.sh
```

### 3. Chaos Tests
Resilience testing under adverse conditions.

**File**: `chaos-test.sh`

**What it tests**:
- Normal start/stop cycle
- Brutal process kill (SIGKILL)
- Module removal while running
- Rapid restarts
- Restart limit enforcement
- Concurrent camera access
- Stop during active stream
- Configuration corruption handling
- Multiple tray instances

**Run**:
```bash
./tests/chaos-test.sh
```

**⚠️ Warning**: Requires sudo for module operations

### 4. Performance Tests
Measures FPS, latency, resource usage.

**File**: `performance-test.sh`

**What it tests**:
- FPS measurement (target: >= 25 fps)
- Latency (time to first frame)
- CPU usage
- Memory usage
- Frame drops
- Sustained load (60s)
- Different resolutions
- Service restart time

**Run**:
```bash
./tests/performance-test.sh
```

### 5. Integration Tests (CI)
Full installation and setup in containers.

**File**: `.github/workflows/integration-test.yml`

**Platforms tested**:
- Arch Linux (container)
- Ubuntu 22.04
- Fedora (container)

**Run automatically on**: Push, Pull Request

## 🚀 Quick Start

### Run all tests
```bash
./tests/run-all.sh
```

### Run specific test suite
```bash
./tests/run-all.sh --smoke-only
./tests/run-all.sh --chaos-only
./tests/run-all.sh --performance-only
./tests/run-all.sh --unit-only
```

### Skip specific tests
```bash
./tests/run-all.sh --no-chaos --no-performance
```

## 📋 Prerequisites

### Required
- `bash`
- `systemd`
- `v4l2loopback-dkms` (for smoke/chaos/performance tests)
- `gstreamer` with plugins

### Optional
- `bats` - For unit tests
- `bc` - For arithmetic comparisons
- `sudo` - For chaos tests (module operations)

### Install on Arch
```bash
sudo pacman -S bats bc v4l2loopback-dkms
```

### Install on Ubuntu
```bash
sudo apt install bats bc v4l2loopback-dkms
```

## 🔧 Test Configuration

### Environment Variables

```bash
# Enable JSON logging for tests
export LOG_FORMAT=json

# Use custom loopback device
export LOOPBACK_DEVICE=/dev/video50

# Test mode (skips interactive prompts)
export TEST_MODE=1
```

## 📊 Test Results Interpretation

### Smoke Test
- ✅ **All green**: System ready for production use
- ⚠️ **Warnings**: May work but with limitations
- ❌ **Failures**: Critical issues, won't work

### Chaos Test
- ✅ **Pass**: Service is resilient
- ❌ **Fail**: Service crashes or doesn't recover

### Performance Test
Benchmarks:
- **FPS**: >= 25 (excellent), >= 15 (usable)
- **Latency**: < 500ms (excellent), < 1s (good), < 3s (acceptable)
- **CPU**: < 30% (low), < 50% (acceptable)
- **Memory**: < 100MB (low), < 200MB (acceptable)

## 🐛 Troubleshooting Tests

### "Module not loaded"
```bash
sudo modprobe v4l2loopback devices=1 video_nr=48 card_label="VirtualCam"
```

### "Service failed to start"
```bash
journalctl --user -u virtualcam.service -n 50
```

### "No video stream"
Check physical camera:
```bash
v4l2-ctl --list-devices
ls -la /dev/video*
```

### Tests hang
Kill all test processes:
```bash
pkill -f "gst-launch"
pkill -f "yad.*VirtualCam"
systemctl --user stop virtualcam.service
```

## 🔄 CI Integration

Tests run automatically on GitHub Actions:

1. **On every push/PR**: Unit tests + ShellCheck
2. **On every push/PR**: Integration tests (Arch, Ubuntu, Fedora)
3. **On release tags**: Full test suite + release creation

## 📝 Writing New Tests

### Adding to bats
```bash
# tests/test_new_feature.bats
@test "new feature works" {
    run ./webcam-tray new-feature
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected output" ]]
}
```

### Adding to smoke-test.sh
```bash
echo "Test N: Description..."
if command_that_should_pass; then
    pass "Test passed"
else
    fail "Test failed"
fi
```

## 🎯 Best Practices

1. **Run smoke tests** before committing
2. **Run chaos tests** before releases
3. **Check performance** after GStreamer pipeline changes
4. **Update tests** when adding new features
5. **Document failures** in issues

## 📞 Getting Help

If tests fail:
1. Check logs: `journalctl --user -u virtualcam.service -n 100`
2. Run with verbose: `bash -x tests/smoke-test.sh`
3. Open issue with test output

## 🏆 Test Coverage

Current coverage:
- ✅ Installation
- ✅ Configuration
- ✅ Service lifecycle
- ✅ Autostart
- ✅ Logging (text & JSON)
- ✅ Hardware detection
- ✅ Error handling
- ✅ Performance metrics
- ✅ Multi-platform (Arch, Ubuntu, Fedora)

## License

Same as parent project (MIT)
