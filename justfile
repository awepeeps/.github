# List available recipes.
default:
    @just --list

# Compare standards/core.md with the other four owner copies.
core-drift:
    bun scripts/core-drift.ts

# Format the files this repository owns.
fmt:
    bun fmt

# Fail when a file needs formatting.
fmt-check:
    bun fmt --check

# Everything CI requires.
check: fmt-check
