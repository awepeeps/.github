#!/usr/bin/env bun
// Repository-level guard: required standard files exist and the shared core is present.
import { existsSync, readFileSync, statSync } from "node:fs";

const required = [
  "AGENTS.md",
  "README.md",
  "LICENSE",
  "favicon.svg",
  ".editorconfig",
  ".gitattributes",
  ".githooks/pre-commit",
  "mise.toml",
  "justfile",
  ".github/dependabot.yml",
  "standards/core.md",
  "standards/owner.md",
  "scripts/core-drift.ts",
];

let failed = false;
for (const path of required) {
  if (!existsSync(path) || statSync(path).size === 0) {
    console.error(`check: missing or empty ${path}`);
    failed = true;
  }
}

const core = readFileSync("standards/core.md", "utf8");
if (!core.startsWith("# Core repository standard\n")) {
  console.error("check: standards/core.md does not start with the shared title");
  failed = true;
}

if (failed) process.exit(1);
console.log(`check: ${required.length} required files present`);
