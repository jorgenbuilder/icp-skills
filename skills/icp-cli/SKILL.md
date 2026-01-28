---
name: icp-cli
description: Guides use of the Internet Computer (ICP) CLI (icp) for local networks, builds, deploys, canister operations, identities, cycles/tokens, recipe system, environments, and advanced features. Use when the user asks about icp-cli, icp commands, canister deployment, local ICP network workflows, recipes, multi-environment deployments, or command help. Also use whenever dfx is mentioned so guidance always maps to icp.
---

# ICP CLI Usage

## Hard rule: no dfx

- Never suggest or use the legacy `dfx` command.
- Any time the user mentions `dfx`, map the request to the equivalent `icp` command(s).
- If a reference or example uses `dfx`, translate it to `icp` before responding.

## Quick start workflow

Default to these steps unless the user asks for a specific command:

**Standard workflow:**

1. Create a project: `icp new my-project`
2. Start local network: `icp network start -d`
3. Deploy (builds automatically): `icp deploy`
4. Call a method: `icp canister call <canister> <method> '(...)'`
5. Verify if needed: `icp network status`, `icp canister status <canister>`

**Recipe-based workflow (modern approach):**

1. Create with recipe: `icp new my-project --recipe @dfinity/rust`
2. Start network: `icp network start -d`
3. Deploy: `icp deploy`
4. Test: `icp canister call <canister> <method> '(...)'`
5. Verify: `icp canister status <canister>`

Recipes (`@dfinity/rust`, `@dfinity/motoko`, `@dfinity/asset-canister`, `@dfinity/prebuilt`) provide best-practice configurations and reduce boilerplate.

Use `-e/--environment` when the user specifies a target (deploy uses environments; network start uses a network name or `-e`).

## Non-interactive project creation

`icp new` may prompt for template values and can fail in non-TTY contexts. Use explicit template settings to avoid prompts:

```
icp new my-project --subfolder hello-world \
  --define backend_type=rust \
  --define frontend_type=react \
  --define network_type=Default
```

**Modern alternative: Use recipes** for cleaner non-interactive project creation:

```
icp new my-project --recipe @dfinity/rust
```

Recipes eliminate template prompts and provide standardized configurations.

## Preflight checks

Use these to confirm the environment quickly:

- `icp --version`
- `icp network list`
- `icp network status` (or `icp network ping --wait-healthy`)

## Command map (common tasks)

**Project lifecycle:**
- `icp new` - Create project (use `--recipe @dfinity/rust` for modern approach)
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
- `icp canister metadata <canister> <section>` - Read metadata sections (NEW in beta.5)
- `icp canister settings show|update|sync` - Manage settings
- `icp canister top-up --amount <amount>` - Add cycles

**Identities:**
- `icp identity new|list|use|default|principal|import|export`
- `icp identity account-id` - Get ledger AccountIdentifier (NEW in beta.5)
- Storage modes: keyring (default), password-protected, plaintext

**Cycles:**
- `icp cycles balance|mint` - Check and mint cycles
- `icp cycles transfer --to <canister> --amount <amount>` - Transfer cycles (NEW in beta.5, replaces `token cycles transfer`)
- Human-friendly amounts: 1k, 1.5m, 2T (NEW in beta.5)

**Tokens:**
- `icp token balance|transfer` - ICP token operations
- Accepts AccountIdentifier hex strings (NEW in beta.5)

**Environments:**
- `icp environment list` - List environments
- Use `-e <env>` for environment-specific commands
- BREAKING (beta.5): Use `-e ic` for mainnet (not `--mainnet`)

**Arguments:**
- `--argument-file <file>` - File-based arguments (Candid or hex, NEW in beta.5)
- Direct hex-encoded arguments supported (NEW in beta.5)

## Decision points

**Recipe selection:**
- Use official `@dfinity/` recipes for standard canister types
- `@dfinity/rust` - Rust canisters (config: `package` = Cargo package name)
- `@dfinity/motoko` - Motoko canisters (config: `main` = main .mo file)
- `@dfinity/asset-canister` - Frontend assets (config: `dir` = asset directory)
- `@dfinity/prebuilt` - Pre-built WASM (config: `path` + `sha256`)
- Pin versions for production: `@dfinity/rust@v3.0.0`
- Use local recipes for custom workflows: `file://recipes/custom.hbs`
- Remote recipes require sha256 for integrity

**Environment strategy:**
- Default to `local` if unspecified
- Use `-e ic` for IC mainnet (BREAKING: not `--mainnet`, removed in beta.5)
- Custom environments defined in icp.yaml: `-e staging`, `-e production`
- Multi-stage workflow: local → staging → ic
- Each environment has separate canister IDs in `.icp/<env>/canister_ids.json`

**Network type:**
- **Managed networks** (default): Native PocketIC, simpler for local dev
- **Containerized networks**: Docker-based, isolated, ideal for CI/CD
- Windows: Docker Desktop required for all local networks (managed or containerized)

**Platform-specific (NEW in beta.5):**
- **Windows**: Native support for Rust canisters; Motoko requires WSL; Docker Desktop required for local networks
- **macOS/Linux**: Full native support for all canister types; Docker optional (only for containerized networks)
- **Large WASM**: Automatic chunking for >2MB (no manual action needed)

**Identity storage:**
- **Production**: Always keyring (OS keychain)
- **Development**: Keyring or password-protected
- **CI/CD**: Password-protected with secrets management
- **Never**: Plaintext for production (insecure)

**Deployment mode:**
- Use `--mode install|reinstall|upgrade` only when user requests it
- Default: auto-detects based on canister state

**Resource allocation:**
- Set `compute_allocation` (0-100%) for performance guarantees
- Set `memory_allocation` for predictable billing
- Configure `freezing_threshold` (default 30 days, recommend 90 days for production)
- Budget 1-2T cycles minimum for production canisters

**Argument format:**
- **Candid IDL** (`.did` files): Human-readable, type-safe, for development
- **Hex-encoded**: Binary data, compact, for CI/CD
- **File-based** (`--argument-file`): Reusable configs, complex arguments (NEW in beta.5)
- **Interactive**: Omit args to trigger prompt (when args unknown)

**Amount format (NEW in beta.5):**
- Use human-friendly: `2T`, `500m`, `1.5b`, `100k` (trillion, million, billion, thousand)
- Or underscores: `2_000_000_000_000`
- Avoid raw numbers (hard to read)

**Controller safety (NEW in beta.5):**
- CLI warns before removing self from controllers
- Use `--force` to skip confirmation (scripts only, dangerous)
- Always maintain multiple controllers for critical canisters

**Legacy compatibility:**
- **Local vs ic**: Use `-e ic` (not `--mainnet` or `--ic`, removed in beta.5)
- **Cycles transfer**: Use `icp cycles transfer` (not `icp token cycles transfer`, removed in beta.5)
- Map all `dfx` commands to `icp` equivalents

## Usage guidance

- **Prefer recipes** for new projects: Reduces boilerplate, enforces best practices
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
- **SHA-256 mismatch**: Recipe content changed, update sha256 hash or use version-pinned recipe (`@dfinity/rust@v3.0.0`)
- **Template expansion errors**: Run `icp project show` to see expanded config and identify issues

**Environment issues:**
- **Wrong network**: Verify `-e <env>` matches intended environment with `icp environment list`
- **Canister not found**: Check `.icp/<env>/canister_ids.json` exists and has correct IDs
- **Settings mismatch**: Use `icp canister settings sync` to apply icp.yaml settings to deployed canisters

**Docker network problems:**
- **Container won't start**: Verify Docker is running (`docker ps`)
- **Windows**: Ensure Docker Desktop is installed and running (required for all local networks)
- **Port conflicts**: Change port in icp.yaml (`ports: ["127.0.0.1:8001:8000"]`)

**Cycles depletion:**
- **Canister frozen**: Top-up with `icp canister top-up --amount 2T <canister>`
- **Low cycles warning**: Monitor with `icp canister status` regularly
- **Prevent freezing**: Increase `freezing_threshold` to 90 days (7776000 seconds)

**Windows-specific (NEW in beta.5):**
- **Motoko build fails**: Motoko requires WSL on Windows, install icp-cli inside WSL
- **Local network fails**: Docker Desktop must be running
- **Rust works, Motoko doesn't**: Expected behavior, use WSL for Motoko development

**Controller lockout:**
- **Warning system**: CLI warns before removing self from controllers (beta.5 feature)
- **Confirmation prompt**: Review carefully, type 'y' only if intentional
- **Skip prompt**: Use `--force` flag (dangerous, scripts only)
- **Already locked out**: Contact other controllers to restore access

**Large WASM (beta.5):**
- **Automatic chunking**: Files >2MB upload automatically in chunks
- **No action needed**: CLI handles chunking transparently
- **Optimize anyway**: Use ic-wasm to reduce deployment cost

**Network naming (BREAKING in beta.5):**
- **--mainnet removed**: Use `-e ic` or `-n ic` instead
- **--ic removed**: Use `-e ic` instead
- **Environment "mainnet" renamed**: Update icp.yaml to use "ic"

## Navigation

This skill provides quick-start guidance. For detailed information:

- **Recipe system, environment configuration, containerized networks, YAML configuration, advanced canister settings, argument handling**: See `reference.md`
- **Practical workflow examples** (recipe-based projects, multi-environment deployment, containerized networks, identity management, cycles management): See `examples.md`
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
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/quickstart/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/tutorial/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/reference/cli/" }
```

Feature-specific guides:
```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/guides/using-recipes/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/guides/creating-recipes/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/guides/managing-environments/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/guides/deploying-to-mainnet/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/guides/containerized-networks/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/guides/managing-identities/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/guides/tokens-and-cycles/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/guides/local-development/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/guides/installation/" }
```

Reference documentation:
```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/reference/configuration/" }
```

```json
{ "tool": "WebFetch", "url": "https://dfinity.github.io/icp-cli/reference/canister-settings/" }
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
{ "tool": "WebFetch", "url": "https://forum.dfinity.org/t/first-beta-release-of-icp-cli/60410" }
```

## Responses

When replying to users:

- Provide the smallest set of commands to accomplish the task.
- Include flags only when necessary to meet the user’s environment or identity needs.
- Offer a short "verify" step (e.g., `icp network status`, `icp canister status`).
- Cite official docs or the CLI help when explaining flags or behavior.
- Ask for missing details only when required: environment/network, canister name, method, and args.

## Self-test prompts

Use these to sanity-check outputs:

- "Start a local network and deploy" → quick start workflow + verify step
- "Create project with Rust recipe" → `icp new my-project --recipe @dfinity/rust`
- "Call a canister method but I don't know args" → omit args to trigger prompt
- "Deploy to staging" → use `-e staging`, avoid `-n`
- "Deploy to IC mainnet" → use `-e ic` (NOT `--mainnet`, removed in beta.5)
- "Check cycles and top up" → `icp cycles balance` + `icp canister top-up --amount 2T`
- "Set up containerized network" → Docker workflow in icp.yaml (Windows: requires Docker Desktop)
- "Top up canister with 2 trillion cycles" → `icp canister top-up --amount 2T <canister>`
- "Get my ledger account ID" → `icp identity account-id`
- "View expanded project config" → `icp project show`
- "Transfer cycles to a canister" → `icp cycles transfer --to <canister> --amount 2T` (NOT `token cycles transfer`)

## Examples

**Create project with recipe and deploy locally**

Commands:

```bash
# Create with Rust recipe
icp new my-project --recipe @dfinity/rust
cd my-project

# Start local network
icp network start -d
icp network status

# Deploy (builds automatically)
icp deploy

# Test
icp canister call backend greet '("World")'

# View expanded config (see what recipe generated)
icp project show
```

For Motoko: use `--recipe @dfinity/motoko` (requires WSL on Windows).
For assets: use `--recipe @dfinity/asset-canister`.

**Multi-environment deployment (local → staging → IC mainnet)**

Commands:

```bash
# 1. Develop and test locally
icp network start -d
icp deploy
icp canister status backend

# 2. Deploy to staging environment
icp deploy -e staging
icp canister status -e staging backend

# 3. Promote to IC mainnet
# IMPORTANT: Use -e ic (not --mainnet, removed in beta.5)
icp deploy -e ic
icp canister status -e ic backend
```

Environment-specific settings configured in `icp.yaml`:

```yaml
environments:
  staging:
    network: ic
    canisters:
      backend:
        settings:
          compute_allocation: 20
  ic:  # Mainnet environment (renamed from "mainnet" in beta.5)
    canisters:
      backend:
        settings:
          compute_allocation: 50
          memory_allocation: 4GB
```

**Check cycles and top up (with human-readable amounts)**

Commands:

```bash
# Check cycles balance
icp cycles balance

# Top up with human-readable amounts (NEW in beta.5)
icp canister top-up --amount 2T backend      # 2 trillion
icp canister top-up --amount 500m backend    # 500 million

# Transfer cycles (NEW command in beta.5)
# Replaces 'icp token cycles transfer'
icp cycles transfer --to rrkah-fqaaa-aaaaa-aaaaq-cai --amount 1.5T

# Check canister cycles
icp canister status backend
```

Supported formats: `1k`, `1.5m`, `2b`, `4T`, `1_000_000`.

**Get account ID and transfer tokens**

Commands:

```bash
# Get your ledger AccountIdentifier (NEW in beta.5)
icp identity account-id
# Output: d4685b31b51450508aff0331584df7692a84467b680326f5c5f7d30ae711682f

# Transfer ICP tokens using AccountIdentifier hex string
icp token transfer \
  --to d4685b31b51450508aff0331584df7692a84467b680326f5c5f7d30ae711682f \
  --amount 10.5

# Check token balance
icp token balance
```

Beta.5 accepts AccountIdentifier hex strings for transfers.

## Sources

Core documentation:
- ICP CLI Documentation: https://dfinity.github.io/icp-cli/
- Quickstart: https://dfinity.github.io/icp-cli/quickstart/
- Tutorial: https://dfinity.github.io/icp-cli/tutorial/
- CLI Reference: https://dfinity.github.io/icp-cli/reference/cli/
- Configuration Reference: https://dfinity.github.io/icp-cli/reference/configuration/
- Canister Settings: https://dfinity.github.io/icp-cli/reference/canister-settings/

Feature-specific guides:
- Using Recipes: https://dfinity.github.io/icp-cli/guides/using-recipes/
- Creating Recipes: https://dfinity.github.io/icp-cli/guides/creating-recipes/
- Managing Environments: https://dfinity.github.io/icp-cli/guides/managing-environments/
- Deploying to Mainnet: https://dfinity.github.io/icp-cli/guides/deploying-to-mainnet/
- Containerized Networks: https://dfinity.github.io/icp-cli/guides/containerized-networks/
- Managing Identities: https://dfinity.github.io/icp-cli/guides/managing-identities/
- Tokens and Cycles: https://dfinity.github.io/icp-cli/guides/tokens-and-cycles/
- Local Development: https://dfinity.github.io/icp-cli/guides/local-development/
- Installation: https://dfinity.github.io/icp-cli/guides/installation/

Repositories and releases:
- ICP CLI Repository: https://github.com/dfinity/icp-cli
- Beta Releases: https://github.com/dfinity/icp-cli/releases
- Recipe Repository: https://github.com/dfinity/icp-cli-recipes
- Forum Announcement (beta.5): https://forum.dfinity.org/t/first-beta-release-of-icp-cli/60410
