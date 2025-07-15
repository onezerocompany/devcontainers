#!/bin/bash
set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REGISTRY="${REGISTRY:-ghcr.io}"
IMAGE_NAME="${IMAGE_NAME:-${GITHUB_REPOSITORY_OWNER:-local}/devcontainer}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
PUSH="${PUSH:-false}"
CACHE_TYPE="${CACHE_TYPE:-local}"
BUILDKIT_VERSION="v0.12.5"

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to build an image with caching
build_image() {
    local context="$1"
    local dockerfile="$2"
    local tags="$3"
    local target="${4:-}"
    local build_args="${5:-}"
    local cache_key="$6"
    
    print_info "Building $cache_key image..."
    
    local build_cmd="docker buildx build"
    build_cmd="$build_cmd --platform $PLATFORMS"
    build_cmd="$build_cmd --file $dockerfile"
    build_cmd="$build_cmd --progress=plain"
    
    # Add tags
    IFS=',' read -ra TAG_ARRAY <<< "$tags"
    for tag in "${TAG_ARRAY[@]}"; do
        build_cmd="$build_cmd --tag $tag"
    done
    
    # Add target if specified
    if [ -n "$target" ]; then
        build_cmd="$build_cmd --target $target"
    fi
    
    # Add build args if specified
    if [ -n "$build_args" ]; then
        IFS=$'\n' read -ra ARG_ARRAY <<< "$build_args"
        for arg in "${ARG_ARRAY[@]}"; do
            build_cmd="$build_cmd --build-arg $arg"
        done
    fi
    
    # Configure caching based on type
    if [ "$CACHE_TYPE" = "registry" ]; then
        # Registry cache (requires push permissions)
        build_cmd="$build_cmd --cache-from type=registry,ref=$REGISTRY/$IMAGE_NAME:buildcache-$cache_key"
        if [ "$PUSH" = "true" ]; then
            build_cmd="$build_cmd --cache-to type=registry,ref=$REGISTRY/$IMAGE_NAME:buildcache-$cache_key,mode=max"
        fi
    else
        # Local cache (default)
        mkdir -p .buildx-cache
        build_cmd="$build_cmd --cache-from type=local,src=.buildx-cache/$cache_key"
        build_cmd="$build_cmd --cache-to type=local,dest=.buildx-cache/$cache_key,mode=max"
    fi
    
    # Push or load
    if [ "$PUSH" = "true" ]; then
        build_cmd="$build_cmd --push"
    else
        # For multi-platform builds, we can't load, so we'll just build
        if [ "$PLATFORMS" = "linux/amd64" ] || [ "$PLATFORMS" = "linux/arm64" ]; then
            build_cmd="$build_cmd --load"
        fi
    fi
    
    # Add context
    build_cmd="$build_cmd $context"
    
    # Execute build
    print_info "Executing: $build_cmd"
    eval $build_cmd
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH="true"
            shift
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --image-name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --platform)
            PLATFORMS="$2"
            shift 2
            ;;
        --cache-type)
            CACHE_TYPE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --push                Push images to registry (default: false)"
            echo "  --registry REGISTRY   Registry to use (default: ghcr.io)"
            echo "  --image-name NAME     Image name (default: \$GITHUB_REPOSITORY_OWNER/devcontainer or local/devcontainer)"
            echo "  --platform PLATFORMS  Platforms to build (default: linux/amd64,linux/arm64)"
            echo "  --cache-type TYPE     Cache type: 'local' or 'registry' (default: local)"
            echo "  --help                Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Setup Docker Buildx
print_info "Setting up Docker Buildx..."
if ! docker buildx ls | grep -q "devcontainer-builder"; then
    docker buildx create --name devcontainer-builder --driver docker-container --driver-opt image=moby/buildkit:$BUILDKIT_VERSION
fi
docker buildx use devcontainer-builder
docker buildx inspect --bootstrap

# Display build configuration
print_info "Build Configuration:"
print_info "  Registry: $REGISTRY"
print_info "  Image Name: $IMAGE_NAME"
print_info "  Platforms: $PLATFORMS"
print_info "  Push: $PUSH"
print_info "  Cache Type: $CACHE_TYPE"

# Build base image (standard target)
build_image \
    "./images/base" \
    "./images/base/Dockerfile" \
    "$REGISTRY/$IMAGE_NAME:base,$REGISTRY/$IMAGE_NAME:latest" \
    "standard" \
    "" \
    "base"

# Build dind image
build_image \
    "./images/base" \
    "./images/base/Dockerfile" \
    "$REGISTRY/$IMAGE_NAME:dind" \
    "dind" \
    "" \
    "dind"

# Build devcontainer standard image
build_image \
    "./images/devcontainer" \
    "./images/devcontainer/Dockerfile" \
    "$REGISTRY/$IMAGE_NAME:devcontainer,$REGISTRY/$IMAGE_NAME:devcontainer-standard" \
    "" \
    "BASE_IMAGE_REGISTRY=$REGISTRY
BASE_IMAGE_NAME=${IMAGE_NAME%/*}/${IMAGE_NAME##*/}
BASE_IMAGE_TAG=base
DIND=false" \
    "devcontainer-standard"

# Build devcontainer dind image
build_image \
    "./images/devcontainer" \
    "./images/devcontainer/Dockerfile" \
    "$REGISTRY/$IMAGE_NAME:devcontainer-dind" \
    "" \
    "BASE_IMAGE_REGISTRY=$REGISTRY
BASE_IMAGE_NAME=${IMAGE_NAME%/*}/${IMAGE_NAME##*/}
BASE_IMAGE_TAG=dind
DIND=true" \
    "devcontainer-dind"

# Build runner image
build_image \
    "./images/runner" \
    "./images/runner/Dockerfile" \
    "$REGISTRY/$IMAGE_NAME:runner" \
    "" \
    "" \
    "runner"

# Build settings-gen image
build_image \
    "./images/settings-gen" \
    "./images/settings-gen/Dockerfile" \
    "$REGISTRY/$IMAGE_NAME:settings-gen" \
    "" \
    "" \
    "settings-gen"

print_info "Build completed successfully!"

# Display built images
if [ "$PUSH" != "true" ] && ([ "$PLATFORMS" = "linux/amd64" ] || [ "$PLATFORMS" = "linux/arm64" ]); then
    print_info "Built images:"
    docker images | grep "$IMAGE_NAME" | head -10
fi

# Display cache information
if [ "$CACHE_TYPE" = "local" ]; then
    print_info "Cache size:"
    du -sh .buildx-cache/* 2>/dev/null || print_warning "No cache found"
fi