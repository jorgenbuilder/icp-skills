---
name: icp-cli
description: Guides use of the Internet Computer (ICP) CLI (icp) v0.1.0 for local networks, builds, deploys, canister operations, identities, cycles/tokens, recipe system, environments, and advanced features. Use when the user asks about icp-cli, icp commands, canister deployment, local ICP network workflows, recipes, multi-environment deployments, or command help. Also use whenever dfx is mentioned so guidance always maps to icp.
---

# ICP CLI Usage

## Hard rule: no dfx

- Never suggest or use the legacy `dfx` command.
- Any time the user mentions `dfx`, map the request to the equivalent `icp` command(s).
- If a reference or example uses `dfx`, translate it to `icp` before responding.

## Quick start workflow

Default to these steps unless the user asks for a specific command:

**Standard workflow (template-based):**

1. Create a project: `icp new my-project` (interactive prompts for template selection)
2. Enter project: `cd my-project`
3. Start local network: `icp network start -d`
4. Deploy (builds automatically): `icp deploy`
5. Call a method: `icp canister call <canister> <method> '(...)'`
6. Verify if needed: `icp network status`, `icp canister status <canister>`

**Non-interactive project creation:**

```
icp new my-project --subfolder hello-world \
  --define backend_type=rust \
  --define frontend_type=react \
  --define network_type=Default
```

**Custom project with recipes:**

1. Create directory: `mkdir my-project && cd my-project`
2. Create `icp.yaml` with recipe configuration (see recipe section)
3. Create source code
4. Start network: `icp network start -d`
5. Deploy: `icp deploy`

Recipes (`@dfinity/rust@v3.0.0`, `@dfinity/motoko@v4.0.0`, `@dfinity/asset-canister@v2.1.0`, `@dfinity/prebuilt@v2.0.0`) provide best-practice configurations and reduce boilerplate. All recipes MUST include an explicit version.

Use `-e/--environment` when the user specifies a target (deploy uses environments; network start uses a network name or `-e`).

## Preflight checks

Use these to confirm the environment quickly:

- `icp --version`
- `icp network list`
- `icp network status` (or `icp network ping --wait-healthy`)

## Command map (common tasks)

**Project lifecycle:**
- `icp new` - Create project from template (uses cargo-generate)
- `icp build` - Build canisters
- `icp deploy` - Deploy canisters (builds automatically)
- `icp sync` - Sync assets to asset canister
- `icp project show` - View expanded configuration (useful for recipes)

**Local network:**
- `icp network start|status|ping|stop`
- Note: Windows requires Docker Desktop for local networks

**Canister operations:**
- `icp canister create|install|call|status|delete|list`
- `icp canister start|stop` - Control canister state
- `icp canister metadata <canister> <section>` - Read metadata sections
- `icp canister settings show|update|sync` - Manage settings
- `icp canister top-up --amount <amount> <canister>` - Add cycles

**Identities:**
- `icp identity new|list|default|principal|import|export|rename|delete`
- `icp identity account-id` - Get ledger AccountIdentifier
- `icp identity link hsm` - Link HSM identity (PKCS#11)
- Storage modes: keyring (default), password-protected, plaintext

**Cycles:**
- `icp cycles balance|mint` - Check and mint cycles
- `icp cycles transfer <amount> <receiver>` - Transfer cycles
- `icp cycles mint --icp <amount>` or `--cycles <amount>` - Convert ICP to cycles
- Human-friendly amounts: 1k, 1.5m, 2T

**Tokens:**
- `icp token balance` - ICP token balance
- `icp token transfer <amount> <receiver>` - ICP token transfer
- `icp token <LEDGER_ID> balance|transfer` - ICRC-1 token operations
- Accepts AccountIdentifier hex strings

**Environments:**
- `icp environment list` - List environments
- Use `-e <env>` for environment-specific commands
- Use `-e ic` for mainnet (not `--mainnet`)

**Arguments:**
- Positional argument can be Candid text, hex, or file path
- `icp canister call <canister> <method> <arg>` where arg can be a file path
- `icp canister install <canister> --args <arg>` where arg can be a file path

## Decision points

**Recipe selection:**
- Use official `@dfinity/` recipes for standard canister types
- `@dfinity/rust@v3.0.0` - Rust canisters (config: `package` = Cargo package name)
- `@dfinity/motoko@v4.0.0` - Motoko canisters (config: `main` = main .mo file, `args` required - see note below)
- `@dfinity/asset-canister@v2.1.0` - Frontend assets (config: `dir` = asset directory)
- `@dfinity/prebuilt@v2.0.0` - Pre-built WASM (config: `path` + `sha256`)
- All recipes MUST specify a version: `@dfinity/rust@v3.0.0` (unversioned is not supported)
- **Motoko v4.0.0 note**: `args` in recipe configuration is currently required (moc compiler flags). Use `args: ""` if no extra flags needed. Will become optional in a future Motoko recipe release.
- Use local recipes for custom workflows: `file://recipes/custom.hbs`
- Remote recipes require sha256 for integrity

**Environment strategy:**
- Default to `local` if unspecified
- Use `-e ic` for IC mainnet (not `--mainnet` or `--ic`, removed since beta.5)
- Custom environments defined in icp.yaml: `-e staging`, `-e production`
- Multi-stage workflow: local → staging → ic
- Each environment has separate canister IDs in `.icp/<env>/canister_ids.json`

**Network vs environment flags (`-n` vs `-e`):**
- `-n` (network): Use for token and cycles operations (`icp token balance -n ic`, `icp cycles mint -n ic`)
- `-e` (environment): Use for canister operations that reference canister names (`icp deploy -e ic`, `icp canister status my-canister -e ic`)
- Canister IDs (not names) can use either flag
- Quick rule: `icp token *` and `icp cycles *` → use `-n`; `icp deploy`, `icp canister *`, `icp build` → use `-e`

**Network type:**
- **Managed networks** (default): Native PocketIC, simpler for local dev
- **Docker networks**: Docker-based, isolated, ideal for CI/CD
- Windows: Docker Desktop required for all local networks

**Platform-specific:**
- **Windows**: Native support for Rust canisters; Motoko requires WSL; Docker Desktop required for local networks
- **macOS/Linux**: Full native support for all canister types; Docker optional (only for Docker-based networks)
- **Large WASM**: Automatic chunking for >2MB (no manual action needed)

**Identity storage:**
- **Production**: Always keyring (OS keychain)
- **Development**: Keyring or password-protected
- **CI/CD**: Password-protected with secrets management
- **HSM**: Hardware security modules via PKCS#11 (`icp identity link hsm`)
- **Never**: Plaintext for production (insecure)

**Local development identity:**
- Local networks use an anonymous identity that is pre-funded with cycles
- No need to create/fund an identity for local development
- Just `icp network start -d && icp deploy` works out of the box

**Deploy output:**
- `icp deploy` prints canister URLs after successful deployment
- Frontend URLs follow the pattern: `http://<canister-id>.localhost:8000`

**Deployment mode:**
- Use `--mode install|reinstall|upgrade` only when user requests it
- Default: auto-detects based on canister state

**Resource allocation:**
- Set `compute_allocation` (0-100%) for performance guarantees
- Set `memory_allocation` for predictable billing
- Configure `freezing_threshold` (default 30 days, recommend 90 days for production)
- Budget 1-2T cycles minimum for production canisters

**Canister settings:**
- `log_visibility`: `controllers` (default), `public`, or `allowed_viewers` with specific principals
- `environment_variables`: Runtime key-value pairs for canister configuration
- `wasm_memory_limit`, `wasm_memory_threshold`: Memory controls

**Amount format:**
- Use human-friendly: `2T`, `500m`, `1.5b`, `100k` (trillion, million, billion, thousand)
- Or underscores: `2_000_000_000_000`
- Avoid raw numbers (hard to read)

**Controller safety:**
- CLI warns before removing self from controllers
- Use `--force` to skip confirmation (scripts only, dangerous)
- Always maintain multiple controllers for critical canisters

**Legacy compatibility:**
- **Local vs ic**: Use `-e ic` (not `--mainnet` or `--ic`, removed since beta.5)
- **Cycles transfer**: Use `icp cycles transfer` (not `icp token cycles transfer`, removed since beta.5)
- **Identity switch**: Use `icp identity default` (not `icp identity use`)
- Map all `dfx` commands to `icp` equivalents

## Common mistakes to avoid

These are frequent errors. Never produce these patterns:

- **Wrong**: `dfx deploy` → **Correct**: `icp deploy` (never use dfx)
- **Wrong**: `icp deploy --mainnet` → **Correct**: `icp deploy -e ic`
- **Wrong**: `icp identity use dev` → **Correct**: `icp identity default dev`
- **Wrong**: `icp token cycles transfer --to X --amount 2T` → **Correct**: `icp cycles transfer 2T X -n ic`
- **Wrong**: `icp token transfer --to X --amount 10` → **Correct**: `icp token transfer 10 X -n ic`
- **Wrong**: `icp cycles mint --amount 5` → **Correct**: `icp cycles mint --icp 5 -n ic` or `--cycles 5T`
- **Wrong**: `icp identity new prod --storage-mode keyring` → **Correct**: `icp identity new prod --storage keyring`
- **Wrong**: `@dfinity/rust` (no version) → **Correct**: `@dfinity/rust@v3.0.0` (version required)
- **Wrong**: `icp new --recipe @dfinity/rust` → **Correct**: `icp new my-project` (recipes go in icp.yaml, not in `icp new`)
- **Wrong**: Using `-e` for token/cycles ops → **Correct**: Use `-n ic` for `icp token` and `icp cycles` commands
- **Wrong**: Motoko recipe without `args` → **Correct**: Include `args: ""` in motoko v4.0.0 recipe configuration
- **Wrong**: `icp canister top-up` for sending cycles to another user → **Correct**: `icp canister top-up` adds cycles to a canister you manage; `icp cycles transfer` sends cycles to any canister/principal

## Usage guidance

- **All recipes MUST include a version**: e.g., `@dfinity/rust@v3.0.0` (unversioned recipes are not supported)
- **Use environments** for multi-stage deployments: `-e local`, `-e staging`, `-e ic`
- **Default to keyring** for identity storage: Most secure option
- **Budget cycles proactively**: 1-2T minimum for production, use human-readable amounts (2T, 500m)
- Default to local network workflows unless a target is specified
- Use `-e/--environment` or `-n/--network` when a target is named, but never both
- Suggest `--identity` when multiple identities might exist
- Provide the minimal command set plus a short verify step
- If call arguments are unknown, omit args to trigger the interactive prompt

## Troubleshooting

**Local network:**
- **Port 8000 already in use**: local PocketIC binds to `localhost:8000`. If `icp network start` fails, check and stop the other process with `lsof -i :8000` and `kill <PID>`.
- **Shutdown**: `icp network stop` (use when finished with local testing).
- **Verify network**: `icp network status` or `icp network ping --wait-healthy`

**Recipe errors:**
- **URL fetch failure**: Check network connection, verify recipe URL is accessible
- **SHA-256 mismatch**: Recipe content changed, update sha256 hash or use a different version-pinned recipe
- **Template expansion errors**: Run `icp project show` to see expanded config and identify issues

**Environment issues:**
- **Wrong network**: Verify `-e <env>` matches intended environment with `icp environment list`
- **Canister not found**: Check `.icp/<env>/canister_ids.json` exists and has correct IDs
- **Settings mismatch**: Use `icp canister settings sync` to apply icp.yaml settings to deployed canisters

**Docker network problems:**
- **Container won't start**: Verify Docker is running (`docker ps`)
- **Windows**: Ensure Docker Desktop is installed and running (required for all local networks)
- **Port conflicts**: Change port in icp.yaml network configuration

**Cycles depletion:**
- **Canister frozen**: Top-up with `icp canister top-up --amount 2T <canister>`
- **Low cycles warning**: Monitor with `icp canister status` regularly
- **Prevent freezing**: Increase `freezing_threshold` to 90 days (7776000 seconds)

**Windows-specific:**
- **Motoko build fails**: Motoko requires WSL on Windows, install icp-cli inside WSL
- **Local network fails**: Docker Desktop must be running
- **Rust works, Motoko doesn't**: Expected behavior, use WSL for Motoko development

**Controller lockout:**
- **Warning system**: CLI warns before removing self from controllers
- **Confirmation prompt**: Review carefully, type 'y' only if intentional
- **Skip prompt**: Use `--force` flag (dangerous, scripts only)
- **Already locked out**: Contact other controllers to restore access

**Large WASM:**
- **Automatic chunking**: Files >2MB upload automatically in chunks
- **No action needed**: CLI handles chunking transparently
- **Optimize anyway**: Use ic-wasm to reduce deployment cost

**Network naming:**
- **--mainnet removed**: Use `-e ic` or `-n ic` instead
- **--ic removed**: Use `-e ic` instead
- **Environment "mainnet" renamed**: Update icp.yaml to use "ic"

## Navigation

This skill provides quick-start guidance. For detailed information:

- **Recipe system, environment configuration, network configuration, YAML configuration, advanced canister settings, argument handling**: See `reference.md`
- **Practical workflow examples** (recipe-based projects, multi-environment deployment, Docker networks, identity management, cycles management): See `examples.md`
- **Security patterns, resource budgeting, platform-specific guidance, migration from dfx**: See `best-practices.md`

## Tool calls

Use tool calls to validate the latest CLI help and documentation.

**CLI help (preferred when available locally):**

```json
{ "tool": "Shell", "command": "icp --help" }
```

```json
{ "tool": "Shell", "command": "icp canister --help" }
```

```json
{ "tool": "Shell", "command": "icp network --help" }
```

**Docs pages (when the CLI isn't available or for citations):**

Core documentation:
```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/quickstart/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/tutorial/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/reference/cli/" }
```

Feature-specific guides:
```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/guides/using-recipes/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/guides/creating-recipes/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/guides/managing-environments/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/guides/deploying-to-mainnet/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/guides/deploying-to-specific-subnets/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/guides/containerized-networks/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/guides/managing-identities/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/guides/tokens-and-cycles/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/guides/local-development/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/guides/installation/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/guides/creating-templates/" }
```

Concept documentation:
```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/concepts/project-model/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/concepts/build-deploy-sync/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/concepts/environments/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/concepts/recipes/" }
```

Reference documentation:
```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/reference/configuration/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/reference/canister-settings/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/reference/environment-variables/" }
```

Migration:
```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/0.1/migration/from-dfx/" }
```

**Repo and releases:**

```json
{ "tool": "WebFetch", "url": "https://github.com/dfinity/icp-cli" }
```

```json
{ "tool": "WebFetch", "url": "https://github.com/dfinity/icp-cli/releases" }
```

```json
{ "tool": "WebFetch", "url": "https://github.com/dfinity/icp-cli-recipes" }
```

```json
{ "tool": "WebFetch", "url": "https://forum.dfinity.org/t/icp-cli-announcements-and-feedback-discussion/60410" }
```

## Responses

When replying to users:

- Provide the smallest set of commands to accomplish the task.
- Include flags only when necessary to meet the user's environment or identity needs.
- Offer a short "verify" step (e.g., `icp network status`, `icp canister status`).
- Cite official docs or the CLI help when explaining flags or behavior.
- Ask for missing details only when required: environment/network, canister name, method, and args.
- All recipe references MUST include a version (e.g., `@dfinity/rust@v3.0.0`).

## Self-test prompts

Use these to sanity-check outputs:

- "Start a local network and deploy" → quick start workflow + verify step
- "Create project with Rust recipe" → `icp new my-project` + `icp.yaml` with `@dfinity/rust@v3.0.0`
- "Call a canister method but I don't know args" → omit args to trigger prompt
- "Deploy to staging" → use `-e staging`, avoid `-n`
- "Deploy to IC mainnet" → use `-e ic` (NOT `--mainnet`)
- "Check cycles and top up" → `icp cycles balance -n ic` + `icp canister top-up --amount 2T <canister> -e ic`
- "Set up Docker-based network" → Docker workflow in icp.yaml
- "Top up canister with 2 trillion cycles" → `icp canister top-up --amount 2T <canister>`
- "Get my ledger account ID" → `icp identity account-id`
- "View expanded project config" → `icp project show`
- "Transfer cycles to a canister" → `icp cycles transfer 2T <canister-id> -n ic`
- "Export my identity" → `icp identity export my-identity > backup.pem`
- "Link HSM identity" → `icp identity link hsm my-hsm --pkcs11-module <path> --key-id 01`
- "Switch default identity" → `icp identity default my-identity` (NOT `icp identity use`)

## Examples

**Create project with template and deploy locally**

Commands:

```bash
# Create with template (interactive)
icp new my-project
cd my-project

# Or non-interactive with specific options
icp new my-project --subfolder hello-world \
  --define backend_type=rust \
  --define frontend_type=react \
  --define network_type=Default && cd my-project

# Start local network
icp network start -d
icp network status

# Deploy (builds automatically)
icp deploy

# Test
icp canister call backend greet '("World")'

# View expanded config (see what recipes generated)
icp project show
```

For Motoko: use `--define backend_type=motoko` (requires WSL on Windows).

**Custom project with recipe-based icp.yaml**

```yaml
# icp.yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
```

```bash
icp network start -d
icp deploy
icp canister call backend greet '("World")'
```

**Multi-environment deployment (local → staging → IC mainnet)**

Commands:

```bash
# 1. Develop and test locally
icp network start -d
icp deploy
icp canister status backend

# 2. Deploy to staging environment
icp deploy -e staging
icp canister status backend -e staging

# 3. Promote to IC mainnet
# IMPORTANT: Use -e ic (not --mainnet)
icp deploy -e ic
icp canister status backend -e ic
```

Environment-specific settings configured in `icp.yaml`:

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend

environments:
  - name: staging
    network: ic
    canisters: [backend]
    settings:
      backend:
        compute_allocation: 20

  - name: production
    network: ic
    canisters: [backend]
    settings:
      backend:
        compute_allocation: 50
        memory_allocation: 4294967296
```

**Check cycles and top up (with human-readable amounts)**

Commands:

```bash
# Check cycles balance
icp cycles balance -n ic

# Top up with human-readable amounts
icp canister top-up --amount 2T backend -e ic     # 2 trillion
icp canister top-up --amount 500m backend -e ic   # 500 million

# Transfer cycles (positional args: amount, receiver)
icp cycles transfer 1.5T rrkah-fqaaa-aaaaa-aaaaq-cai -n ic

# Check canister cycles
icp canister status backend -e ic
```

Supported formats: `1k`, `1.5m`, `2b`, `4T`, `1_000_000`.

**Get account ID and transfer tokens**

Commands:

```bash
# Get your ledger AccountIdentifier
icp identity account-id
# Output: d4685b31b51450508aff0331584df7692a84467b680326f5c5f7d30ae711682f

# Transfer ICP tokens (positional args: amount, receiver)
icp token transfer 10.5 d4685b31b51450508aff0331584df7692a84467b680326f5c5f7d30ae711682f -n ic

# Check token balance
icp token balance -n ic

# ICRC-1 token (e.g., ckBTC)
icp token mxzaz-hqaaa-aaaar-qaada-cai balance -n ic
```

## Sources

Core documentation:
- ICP CLI Documentation: https://dfinity.github.io/icp-cli/0.1/
- Quickstart: https://dfinity.github.io/icp-cli/0.1/quickstart/
- Tutorial: https://dfinity.github.io/icp-cli/0.1/tutorial/
- CLI Reference: https://dfinity.github.io/icp-cli/0.1/reference/cli/
- Configuration Reference: https://dfinity.github.io/icp-cli/0.1/reference/configuration/
- Canister Settings: https://dfinity.github.io/icp-cli/0.1/reference/canister-settings/
- Environment Variables: https://dfinity.github.io/icp-cli/0.1/reference/environment-variables/

Feature-specific guides:
- Using Recipes: https://dfinity.github.io/icp-cli/0.1/guides/using-recipes/
- Creating Recipes: https://dfinity.github.io/icp-cli/0.1/guides/creating-recipes/
- Creating Templates: https://dfinity.github.io/icp-cli/0.1/guides/creating-templates/
- Managing Environments: https://dfinity.github.io/icp-cli/0.1/guides/managing-environments/
- Deploying to Mainnet: https://dfinity.github.io/icp-cli/0.1/guides/deploying-to-mainnet/
- Deploying to Specific Subnets: https://dfinity.github.io/icp-cli/0.1/guides/deploying-to-specific-subnets/
- Containerized Networks: https://dfinity.github.io/icp-cli/0.1/guides/containerized-networks/
- Managing Identities: https://dfinity.github.io/icp-cli/0.1/guides/managing-identities/
- Tokens and Cycles: https://dfinity.github.io/icp-cli/0.1/guides/tokens-and-cycles/
- Local Development: https://dfinity.github.io/icp-cli/0.1/guides/local-development/
- Installation: https://dfinity.github.io/icp-cli/0.1/guides/installation/

Concept documentation:
- Project Model: https://dfinity.github.io/icp-cli/0.1/concepts/project-model/
- Build, Deploy, Sync: https://dfinity.github.io/icp-cli/0.1/concepts/build-deploy-sync/
- Environments and Networks: https://dfinity.github.io/icp-cli/0.1/concepts/environments/
- Recipes: https://dfinity.github.io/icp-cli/0.1/concepts/recipes/

Migration:
- From dfx: https://dfinity.github.io/icp-cli/0.1/migration/from-dfx/

Repositories and releases:
- ICP CLI Repository: https://github.com/dfinity/icp-cli
- Releases: https://github.com/dfinity/icp-cli/releases
- Recipe Repository: https://github.com/dfinity/icp-cli-recipes
- Forum Announcement: https://forum.dfinity.org/t/icp-cli-announcements-and-feedback-discussion/60410
