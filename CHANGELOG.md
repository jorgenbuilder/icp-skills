# ICP Skills Changelog

## [2026-02-13] - ICP CLI Skill v0.1.0 Update

- **v0.1.0 stable release**: Updated all 4 skill files to match icp-cli v0.1.0 (first stable release)
- **Documentation URLs**: All links now point to versioned docs at `https://dfinity.github.io/icp-cli/0.1/`
- **Recipe versioning required**: All recipes must include explicit version (e.g., `@dfinity/rust@v3.0.0`), unversioned recipes no longer supported
- **Recipe versions**: rust@v3.0.0, motoko@v4.0.0, asset-canister@v2.1.0, prebuilt@v2.0.0
- **Motoko args**: Documented that `args` (moc compiler flags) is required in motoko@v4.0.0 recipe configuration; use `args: ""` for no extra flags
- **New identity commands**: `export`, `delete`, `rename`, `link hsm` (PKCS#11 HSM support)
- **YAML format update**: List-based canister/network/environment config (matching v0.1.0 schema)
- **Command syntax fixes**: Positional args for `token transfer` and `cycles transfer`, `icp identity default` replaces `use`, `icp cycles mint --icp/--cycles`
- **New features**: `log_visibility` setting (public/controllers/allowed_viewers), `environment_variables` as key-value pairs, ICRC-1 token support, `-n`/`-e` flag distinction
- **New doc sections**: Concepts (project-model, build-deploy-sync, environments, recipes), deploying-to-specific-subnets, creating-templates, environment-variables reference, migration/from-dfx
- **Docker port fix**: Container port is 4943 (not 8000), port mappings corrected to `"8000:4943"`
- **LLM improvements**: Added "Common mistakes to avoid" section, enhanced `-n`/`-e` quick rule, anonymous identity for local dev, deploy URL output note, `canister top-up` vs `cycles transfer` distinction
- **Forum URL**: Updated to https://forum.dfinity.org/t/icp-cli-announcements-and-feedback-discussion/60410

## [2026-01-28] - ICP CLI Skill Major Update

- **15x expansion**: Comprehensive beta.5 coverage with recipe system, multi-environment deployments, and advanced features (197 → 3,026 lines across 4 organized files)
- **Modern DX**: Human-readable amounts (2T cycles), automatic WASM chunking, controller safety warnings, and `icp identity account-id` command
- **Production-ready**: Security patterns, resource budgeting (1-2T minimum), platform-specific guidance (Windows/WSL, Docker), and dfx migration paths
- **Breaking changes**: `--mainnet` → `-e ic`, `token cycles transfer` → `cycles transfer` (fully documented with examples)

## Previous

- **[2026-01-27]** Forum research skill with comprehensive DFINITY Forum navigation
- **[2026-01-26]** PIC.js skill for local canister testing
- **[Earlier]** Original icp-cli skill (basic 197-line quick-start guide)
