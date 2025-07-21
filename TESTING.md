# PR Testing Setup

This repository now includes automated testing for all pull requests to ensure code quality and prevent issues from being merged.

## What Gets Tested

The PR testing workflow (`.github/workflows/test.yml`) automatically tests:

- **Features**: All devcontainer features using the existing test infrastructure
- **Templates**: Devcontainer template builds and basic functionality  
- **Images**: Docker image builds without publishing
- **Structure**: JSON validation and metadata checks

## How It Works

### Smart Testing
The workflow uses change detection to only test components that have been modified:
- Only tests features if `features/**` files changed
- Only tests templates if `templates/**` files changed  
- Only tests images if `images/**` files changed
- Always runs validation checks

### Test Jobs

1. **Validation**: 
   - JSON syntax validation for all `.json` files
   - Feature structure validation (required files, permissions)
   - Template structure validation (required files)

2. **Feature Testing**:
   - Uses existing `dev-container-features-test-lib` infrastructure
   - Runs `test.sh` scripts in `features/test/*/` directories
   - Tests multiple scenarios defined in `scenarios.json`

3. **Template Testing**:
   - Builds devcontainer templates using `devcontainers/ci@v0.3`
   - Validates basic functionality within the built containers
   - Tests Docker functionality for dind template

4. **Image Testing**:
   - Builds Docker images for multi-platform support
   - Tests that images can run successfully
   - Validates basic tools and user setup

## Running Tests Locally

You can run validation checks locally using:

```bash
# Run all JSON validation
find . -name "*.json" -type f | xargs -I {} jq empty {}

# Check feature structure  
for feature in features/src/*/; do
    [ -f "$feature/devcontainer-feature.json" ] || echo "Missing metadata"
    [ -x "$feature/install.sh" ] || echo "Missing/non-executable install.sh"
done

# Check template structure
for template in templates/*/; do
    [ -f "$template/devcontainer-template.json" ] || echo "Missing template metadata"
    [ -f "$template/.devcontainer/devcontainer.json" ] || echo "Missing devcontainer config"
done
```

## Adding New Tests

### For Features
1. Create test directory: `features/test/<feature-name>/`
2. Add `test.sh` script using `dev-container-features-test-lib`
3. Add `scenarios.json` with test configurations
4. Update the feature matrix in `.github/workflows/test.yml`

### For Templates  
1. Templates are tested automatically when added to `templates/`
2. Update the template matrix in `.github/workflows/test.yml`

### For Images
1. Images are tested automatically when added to `images/`
2. Update the image matrix in `.github/workflows/test.yml`

## Test Results

The workflow provides a detailed summary showing:
- ✅ Components that passed testing
- ❌ Components that failed testing  
- ⏭️ Components that were skipped (no changes)

All tests must pass before a PR can be merged.