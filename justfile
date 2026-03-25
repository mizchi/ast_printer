# MoonBit Project Commands

# Default target
target := "js"

# Default task: check and test
default: check test

# Format code
fmt:
    moon fmt

# Check formatting without rewriting files
fmt-check:
    moon fmt --check

# Type check
check:
    moon check --deny-warn --target {{target}}

# Run tests
test:
    moon test --target {{target}}

# Update snapshot tests
test-update:
    moon test --update --target {{target}}

# Generate type definition files
info:
    moon info

# Verify generated type definition files are up to date
info-check:
    moon info
    git diff --exit-code -- ':(glob)**/*.generated.mbti'

# Clean build artifacts
clean:
    moon clean

# Verify generated Rust code compiles and passes cargo test
cargo-test:
    #!/usr/bin/env bash
    set -euo pipefail
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    cd "$tmpdir" && cargo init --name test_generated -q
    cp "{{justfile_directory()}}/fixtures/expected.rs" "$tmpdir/src/main.rs"
    cargo test -q

# CI checks
ci: fmt-check info-check check test cargo-test
