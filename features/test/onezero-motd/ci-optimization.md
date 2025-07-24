# CI/CD Test Optimization Guide for OneZero MOTD

## Overview
This guide provides strategies to optimize test execution in CI/CD pipelines.

## Test Execution Strategies

### 1. **Tiered Testing Approach**

```yaml
# .github/workflows/test.yml
jobs:
  smoke-tests:
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - name: Quick smoke test
        run: devcontainer features test --scenario smoke
  
  core-tests:
    needs: smoke-tests
    runs-on: ubuntu-latest
    timeout-minutes: 5
    strategy:
      matrix:
        scenario: [default, custom-logo, disabled]
    steps:
      - name: Run core tests
        run: devcontainer features test --scenario ${{ matrix.scenario }}
  
  extended-tests:
    needs: core-tests
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    timeout-minutes: 10
    strategy:
      matrix:
        scenario: [minimal-utils, large-config]
```

### 2. **Container Layer Caching**

```yaml
- name: Setup Docker Buildx
  uses: docker/setup-buildx-action@v2
  with:
    driver-opts: |
      image=moby/buildkit:latest
      network=host
    
- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-buildx-
```

### 3. **Parallel Execution Matrix**

```yaml
strategy:
  matrix:
    test-group:
      - name: "Critical"
        scenarios: "smoke,default"
        timeout: 3
      - name: "Configuration"
        scenarios: "custom-logo,disabled"
        timeout: 5
      - name: "Edge Cases"
        scenarios: "minimal-utils,large-config"
        timeout: 8
  max-parallel: 3
```

## Performance Optimizations

### Test File Optimizations

1. **Cached Execution**: ~85% faster
   ```bash
   # Before: 7 executions
   test1=$(/etc/update-motd.d/50-onezero | grep X)
   test2=$(/etc/update-motd.d/50-onezero | grep Y)
   
   # After: 1 execution
   OUTPUT=$(/etc/update-motd.d/50-onezero)
   test1=$(echo "$OUTPUT" | grep X)
   test2=$(echo "$OUTPUT" | grep Y)
   ```

2. **Batch Operations**: ~70% faster
   ```bash
   # Before: Multiple checks
   check "file1" test -f /path/file1
   check "file2" test -f /path/file2
   check "file3" test -f /path/file3
   
   # After: Single check
   check "all files" bash -c '[ -f /path/file1 ] && [ -f /path/file2 ] && [ -f /path/file3 ]'
   ```

3. **Early Exit**: Saves unnecessary operations
   ```bash
   # Check critical requirements first
   [ -f /etc/update-motd.d/50-onezero ] || { echo "Not installed"; exit 1; }
   ```

### Container Optimizations

1. **Smaller Base Images**
   - `busybox:latest` (1.36MB) for smoke tests
   - `alpine:latest` (7.38MB) for minimal tests
   - `debian:bookworm-slim` (74.8MB) for full tests

2. **Pre-built Test Images**
   ```dockerfile
   FROM debian:bookworm-slim AS test-base
   RUN apt-get update && apt-get install -y procps bc
   ```

3. **Multi-stage Testing**
   ```yaml
   - name: Build test image
     run: |
       docker build -t test-base -f test/Dockerfile.base .
       docker tag test-base:latest ${{ env.REGISTRY }}/test-base:latest
   ```

## Monitoring and Metrics

### Key Metrics to Track
- Total test duration
- Individual scenario timing
- Container pull/build time
- Test failure rate by scenario

### Example Monitoring Script
```bash
#!/bin/bash
START_TIME=$(date +%s)

# Run tests with timing
for scenario in smoke default custom-logo disabled; do
    SCENARIO_START=$(date +%s)
    devcontainer features test --scenario $scenario
    SCENARIO_END=$(date +%s)
    echo "Scenario $scenario: $((SCENARIO_END - SCENARIO_START))s"
done

END_TIME=$(date +%s)
echo "Total duration: $((END_TIME - START_TIME))s"
```

## Best Practices

1. **Use Conditional Testing**
   ```yaml
   - name: Determine test scope
     run: |
       if [[ "${{ github.event_name }}" == "push" ]]; then
         echo "TEST_SCOPE=smoke,default" >> $GITHUB_ENV
       else
         echo "TEST_SCOPE=all" >> $GITHUB_ENV
       fi
   ```

2. **Implement Test Sharding**
   ```yaml
   strategy:
     matrix:
       shard: [1, 2, 3]
       total-shards: [3]
   ```

3. **Cache Test Results**
   ```yaml
   - name: Cache test results
     uses: actions/cache@v3
     with:
       path: test-results/
       key: test-results-${{ github.sha }}
   ```

## Expected Performance Gains

| Optimization | Before | After | Improvement |
|--------------|--------|-------|-------------|
| Smoke test only | 2m 30s | 15s | 90% faster |
| Cached output | 45s | 8s | 82% faster |
| Parallel matrix | 5m (sequential) | 2m | 60% faster |
| Container caching | 3m | 30s | 83% faster |
| **Total Pipeline** | **10m 30s** | **3m 15s** | **69% faster** |

## Implementation Checklist

- [ ] Implement tiered testing (smoke → core → extended)
- [ ] Enable Docker layer caching
- [ ] Use parallel test execution
- [ ] Optimize test files with caching
- [ ] Monitor and track metrics
- [ ] Review and adjust timeout values
- [ ] Document expected durations