set shell := ["bash", "-euo", "pipefail", "-c"]

# List the recipes.
default:
    @just --list

# Install the pinned tools from mise.toml.
install:
    mise install

# Format the files this repository owns.
fmt:
    bun scripts/format.ts

# Fail when a file needs formatting.
fmt-check:
    bun scripts/format.ts --check

# Lint the workflows.
lint:
    actionlint
    zizmor .github/workflows

# Check the required community and standard files.
test:
    bun scripts/check.ts

# Everything CI requires.
check: fmt-check lint test

# Install the committed git hooks.
hooks:
    git config --local core.hooksPath .githooks

# Fail when .agents/skills and .claude/skills disagree.
agent-files:
    bun scripts/agent-files.ts

# Compare standards/core.md with the other four owner copies.
core-drift:
    bun scripts/core-drift.ts

# Audit every repository of this owner against the core and owner standards.
# `just fleet-audit --timing` adds the C5.1 median pull request CI wall time.
fleet-audit *args:
    bun scripts/fleet-audit.ts {{args}}
