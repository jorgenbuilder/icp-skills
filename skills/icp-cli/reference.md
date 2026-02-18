# ICP CLI Reference

Detailed reference for the ICP CLI v0.1.0 recipe system, environment management, network configuration, YAML configuration, and advanced features.

## Recipe System

### What Are Recipes?

Recipes are reusable Handlebars templates that define build and sync configuration for canisters. They reduce boilerplate, enforce best practices, ensure consistency across projects, and improve maintainability.

Instead of manually configuring build steps, source files, and sync operations, recipes encapsulate common patterns in a single reusable template.

### Why Use Recipes?

- **Less boilerplate**: Define canister configuration in 2-3 lines instead of dozens
- **Best practices**: Official recipes follow DFINITY's recommended patterns
- **Consistency**: Same recipe across projects ensures uniform configuration
- **Maintainability**: Recipe updates propagate to all projects using that recipe
- **Version pinning**: Lock to specific recipe versions for reproducible builds

### Official @dfinity Recipes

The `@dfinity` namespace provides officially-supported recipes from the [icp-cli-recipes repository](https://github.com/dfinity/icp-cli-recipes):

All recipes MUST include an explicit version. Unversioned recipes are not supported.

**@dfinity/rust** - Rust canister

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend  # Cargo package name
```

**@dfinity/motoko** - Motoko canister

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/motoko@v4.0.0"
      configuration:
        main: src/main.mo       # Main Motoko file
        args: ""                 # moc compiler flags (required in v4.0.0, will become optional)
```

Use `args: --incremental-gc` to enable incremental GC, or `args: ""` for no extra flags. Omitting `args` entirely causes a template error in v4.0.0.

**@dfinity/asset-canister** - Frontend assets

```yaml
canisters:
  - name: frontend
    recipe:
      type: "@dfinity/asset-canister@v2.1.0"
      configuration:
        dir: dist  # Directory containing built assets
```

**@dfinity/prebuilt** - Pre-built WASM module

```yaml
canisters:
  - name: prebuilt
    recipe:
      type: "@dfinity/prebuilt@v2.0.0"
      configuration:
        path: ./target/wasm32-unknown-unknown/release/canister.wasm
        sha256: "abc123..."  # SHA-256 hash for integrity verification
```

### Recipe Shorthand

The `@dfinity/` shorthand automatically resolves to the recipe repository:

```
@dfinity/rust@v3.0.0
```

is equivalent to:

```
https://github.com/dfinity/icp-cli-recipes/releases/download/rust-v3.0.0/recipe.hbs
```

### Version Pinning (Required)

All recipes MUST specify a version:

```yaml
recipe:
  type: "@dfinity/rust@v3.0.0"  # Locked to v3.0.0
  configuration:
    package: backend
```

Unversioned recipes (e.g., `@dfinity/rust` without a version) are not supported. Always pin to a specific version for reproducible builds.

### Local Recipes

Use project-specific Handlebars templates for custom build workflows:

```yaml
canisters:
  - name: backend
    recipe:
      type: "file://recipes/my-custom-recipe.hbs"
      configuration:
        custom_option: value
```

Local recipes are useful for:
- Organization-specific build patterns
- Experimental configurations
- Recipes not yet published

### Remote Recipes

Reference any recipe URL with SHA-256 integrity verification:

```yaml
canisters:
  - name: backend
    recipe:
      type: "https://example.com/recipes/custom.hbs"
      sha256: "abc123..."  # Required for integrity
      configuration:
        option: value
```

### Viewing Expanded Configuration

Recipes are templates that expand to full configuration. View the expanded config:

```bash
icp project show
```

This displays the complete YAML after recipe expansion, useful for:
- Understanding what a recipe generates
- Debugging configuration issues
- Learning recipe structure

### Recipe Configuration Schema

Each recipe defines its own configuration options. Check recipe documentation for available fields:

- **@dfinity/rust**: `package` (Cargo package name)
- **@dfinity/motoko**: `main` (main Motoko file path), `args` (moc compiler flags, required in v4.0.0 - use `""` if no flags needed)
- **@dfinity/asset-canister**: `dir` (asset directory)
- **@dfinity/prebuilt**: `path` (WASM file), `sha256` (integrity hash)

Custom recipes may define arbitrary configuration fields.

### Combining Recipes with Settings

Recipes define only build and sync configuration. Add canister settings separately:

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    settings:
      compute_allocation: 10
      memory_allocation: 1073741824
      controllers:
        - aaaaa-aa
```

### When to Use Recipes

**Use recipes when:**
- Starting a new project with standard canister types (Rust, Motoko, assets)
- Following official best practices
- Working in teams requiring consistent configuration
- Deploying multiple similar canisters

**Use manual configuration when:**
- Recipe overhead isn't justified (very simple projects)
- Highly custom build workflows
- Learning how build configuration works

## Environment Management

### What Are Environments?

Environments combine a network, canister IDs, and environment-specific configuration. They enable multi-stage deployment workflows (development → staging → production) with different settings per stage.

### Default Environments

Two environments are available by default:

- **`local`**: Points to local PocketIC network (default for most commands)
- **`ic`**: Points to Internet Computer mainnet

Use with `-e` or `--environment`:

```bash
icp deploy -e local   # Deploy to local network
icp deploy -e ic      # Deploy to IC mainnet
```

### Network vs Environment Flags (-n vs -e)

Understanding when to use each flag is essential:

| Flag | Purpose | Used With | Example |
|------|---------|-----------|---------|
| `-n ic` | Network flag | Token and cycles operations | `icp token balance -n ic`, `icp cycles mint -n ic` |
| `-e ic` | Environment flag | Deployment and canister operations | `icp deploy -e ic`, `icp canister status my-canister -e ic` |

**Canister names** (like `my-canister`) must use `-e <environment>` because the environment knows about your project's canister mappings.

**Canister IDs** (like `ryjl3-tyaaa-aaaaa-aaaba-cai`) can use either `-e` or `-n`.

### Custom Environments

Define custom environments in `icp.yaml`:

```yaml
environments:
  - name: staging
    network: ic
    canisters: [backend]
    settings:
      backend:
        compute_allocation: 5

  - name: production
    network: ic
    canisters: [backend]
    settings:
      backend:
        compute_allocation: 20
        memory_allocation: 2147483648
```

Deploy to custom environments:

```bash
icp deploy -e staging
icp deploy -e production
```

### Environment-Specific Settings

Override canister settings per environment:

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    settings:
      compute_allocation: 10  # Default

environments:
  - name: production
    network: ic
    canisters: [backend]
    settings:
      backend:
        compute_allocation: 50  # Override for production
        memory_allocation: 4294967296
```

### Canister ID Management

Canister IDs are stored per-environment in `.icp/<environment>/canister_ids.json`:

```
.icp/
  local/
    canister_ids.json       # Local network IDs
  staging/
    canister_ids.json       # Staging IDs
  production/
    canister_ids.json       # Production IDs
```

Commit environment-specific `canister_ids.json` files to preserve IDs across deployments.

### Commands

List environments:

```bash
icp environment list
```

Deploy to specific environment:

```bash
icp deploy -e <environment>
icp canister status <canister> -e <environment>
icp canister call <canister> <method> -e <environment>
```

### Multi-Stage Deployment Workflow

Standard workflow for promoting changes:

1. **Develop locally**: `icp deploy` (defaults to local environment)
2. **Test in staging**: `icp deploy -e staging`
3. **Promote to production**: `icp deploy -e production`

Each stage uses different canister IDs and can have different resource allocations.

## Network Configuration

### Managed Networks

Default local development networks using native PocketIC:

```yaml
networks:
  - name: local
    mode: managed
    gateway:
      host: 127.0.0.1
      port: 8000
```

### Docker Networks

Docker-based networks for isolation and CI/CD:

```yaml
networks:
  - name: local
    mode: managed
    image: ghcr.io/dfinity/icp-cli-network-launcher
    port-mapping:
      - "8000:4943"
```

### Connected Networks

Connect to external networks:

```yaml
networks:
  - name: testnet
    mode: connected
    url: https://testnet.ic0.app
    root-key: <hex-encoded-key>
```

### Network Options

Configure local network features:

```yaml
networks:
  - name: local
    mode: managed
    ii: true                    # Enable Internet Identity
    nns: true                   # Enable Network Nervous System
    subnets:                    # Configure subnet types
      - application
      - application
    artificial_delay_ms: 50     # Simulate network latency
```

### Platform Requirements

**Windows:**
- Docker Desktop is **required** for local networks (both managed and Docker-based)
- Native Rust canister support
- Motoko canisters require WSL (Motoko compiler doesn't run on Windows)

**macOS/Linux:**
- Native support for all canister types
- Docker required only for Docker-based networks (optional for managed networks)

### When to Use Docker Networks

**Use Docker-based networks when:**
- Running CI/CD pipelines
- Developing multiple projects simultaneously
- Requiring strict network isolation
- Working in teams with reproducible environments

**Use managed networks when:**
- Quick local development
- Single project workflow
- Minimal Docker overhead desired

## YAML Configuration

### Structure

The `icp.yaml` file has three main sections:

```yaml
canisters:    # Canister definitions (list)
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend

networks:     # Network definitions (list, optional)
  - name: local
    mode: managed

environments: # Environment definitions (list, optional)
  - name: production
    network: ic
```

### Canister Configuration with Recipes

Recipe-based canister definition:

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"  # Recipe type (version required)
      configuration:                 # Recipe-specific config
        package: backend
    settings:                        # Canister settings (separate)
      compute_allocation: 10
```

### Recipe Configuration Examples

**Rust canister:**

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend  # Matches Cargo.toml package name
```

**Motoko canister:**

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/motoko@v4.0.0"
      configuration:
        main: src/backend/main.mo  # Path to main Motoko file
        args: ""                    # Required in v4.0.0 (use "" or e.g. --incremental-gc)
```

**Asset canister:**

```yaml
canisters:
  - name: frontend
    recipe:
      type: "@dfinity/asset-canister@v2.1.0"
      configuration:
        dir: dist  # Directory with built frontend assets
```

**Prebuilt WASM:**

```yaml
canisters:
  - name: prebuilt
    recipe:
      type: "@dfinity/prebuilt@v2.0.0"
      configuration:
        path: ./custom.wasm
        sha256: "abc123def456..."  # SHA-256 hash for integrity
```

### External File References

Reference external canister files or use glob patterns:

```yaml
canisters:
  - path/to/canister.yaml
  - canisters/*
  - services/**/*.yaml
```

### Build Configuration

Recipes handle build configuration automatically. For manual builds:

```yaml
canisters:
  - name: custom
    build:
      steps:
        - type: script
          commands:
            - cargo build --release --target wasm32-unknown-unknown
            - cp target/wasm32-unknown-unknown/release/custom.wasm "$ICP_WASM_OUTPUT_PATH"
```

### Pre-built Steps

Use existing WASM from local file or remote URL:

```yaml
canisters:
  - name: prebuilt
    build:
      steps:
        - type: pre-built
          path: dist/canister.wasm
          sha256: abc123...
```

### Sync Steps for Asset Uploads

Asset canisters use sync steps to upload files:

```yaml
canisters:
  - name: frontend
    recipe:
      type: "@dfinity/asset-canister@v2.1.0"
      configuration:
        dir: dist  # Recipe handles sync automatically
```

### Environment Variables in Settings

Pass environment variables to canisters (key-value pairs):

```yaml
canisters:
  - name: backend
    settings:
      environment_variables:
        API_KEY: "secret-key"
        LOG_LEVEL: "debug"
```

### init_args Configuration

Canister initialization arguments (Candid text, hex, or file path):

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    init_args: "(record { admin = principal \"aaaaa-aa\" })"
```

Or hex format:

```yaml
canisters:
  - name: backend
    init_args: "4449444c016d7b0100010203"
```

### Modular Project Organization

Import configuration from external files:

```yaml
# icp.yaml
canisters:
  - canisters/backend.yaml
  - canisters/frontend.yaml
```

```yaml
# canisters/backend.yaml
name: backend
recipe:
  type: "@dfinity/rust@v3.0.0"
  configuration:
    package: backend
```

### Combining Recipes with Settings

Recipes define build/sync configuration. Settings are defined separately:

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    settings:                    # Separate from recipe
      compute_allocation: 20
      memory_allocation: 2147483648
      controllers:
        - aaaaa-aa
        - bbbbb-bb
      freezing_threshold: 2592000  # 30 days in seconds
```

## Advanced Canister Settings

### Complete Settings List

All available canister settings:

```yaml
settings:
  compute_allocation: 10              # Percentage (0-100)
  memory_allocation: 2147483648       # Max memory (bytes)
  freezing_threshold: 2592000         # Seconds (default: 30 days)
  reserved_cycles_limit: 1000000000000  # Max cycles reserved
  wasm_memory_limit: 1073741824       # Max WASM memory (bytes)
  wasm_memory_threshold: 536870912    # Low-memory callback threshold (bytes)
  log_visibility: controllers         # Who can read logs
  environment_variables:              # Runtime key-value pairs
    KEY: "value"
  controllers:                        # Controller principals
    - aaaaa-aa
    - bbbbb-bb
```

### Compute Allocation

Percentage of compute resources guaranteed (0-100). Higher allocation = higher cycle cost:

```yaml
settings:
  compute_allocation: 50  # 50% of compute resources guaranteed
```

Use for latency-sensitive canisters requiring predictable performance.

### Memory Allocation

Maximum memory the canister can use (in bytes):

```yaml
settings:
  memory_allocation: 4294967296  # 4GB
```

Memory is billed based on allocation, not usage.

### Freezing Threshold

Cycles reserve to prevent freezing (in seconds). Default is 30 days (2592000 seconds):

```yaml
settings:
  freezing_threshold: 7776000  # 90 days
```

Higher threshold = more cycles held in reserve = safer from freezing.

### Reserved Cycles Limit

Maximum cycles that can be reserved:

```yaml
settings:
  reserved_cycles_limit: 10000000000000  # ~10T cycles
```

### WASM Memory Limit

Maximum memory available to WASM execution:

```yaml
settings:
  wasm_memory_limit: 3221225472  # 3GB
```

### WASM Memory Threshold

Memory threshold that triggers low-memory callbacks:

```yaml
settings:
  wasm_memory_threshold: 536870912  # 512MB
```

### Log Visibility

Control who can read canister logs:

```yaml
# Only controllers (default)
settings:
  log_visibility: controllers

# Anyone can read logs
settings:
  log_visibility: public

# Specific principals can view logs
settings:
  log_visibility:
    allowed_viewers:
      - "aaaaa-aa"
      - "2vxsx-fae"
```

### Environment Variables

Runtime configuration for canisters (key-value pairs):

```yaml
settings:
  environment_variables:
    API_URL: "https://api.example.com"
    DEBUG: "false"
    FEATURE_FLAGS: "advanced=true"
```

### Setting at Canister vs Environment Level

**Canister level** (applies to all environments):

```yaml
canisters:
  - name: backend
    settings:
      compute_allocation: 10
```

**Environment level** (overrides canister settings):

```yaml
environments:
  - name: production
    network: ic
    canisters: [backend]
    settings:
      backend:
        compute_allocation: 50  # Production gets more compute
```

### Subnet Selection

Deploy to specific subnet during creation:

```bash
icp canister create backend --subnet <subnet-id>
```

### Settings Commands

Show current settings:

```bash
icp canister settings show <canister>
```

Update settings:

```bash
icp canister settings update <canister> --compute-allocation 20
icp canister settings update <canister> --log-visibility public
icp canister settings update <canister> --add-log-viewer <principal>
```

Sync settings from YAML:

```bash
icp canister settings sync <canister>
```

## Argument Handling

### Positional Arguments

In v0.1.0, canister call and install arguments are positional and can be Candid text, hex-encoded bytes, or file paths:

```bash
# Candid text
icp canister call backend init '(record { name = "My Canister" })'

# Hex-encoded
icp canister call backend method 4449444C0001710B48656C6C6F20576F726C64

# File path (Candid or hex content)
icp canister call backend init args/init.did
```

### Install Arguments

```bash
# With Candid args
icp canister install backend --args '(record { admin = principal "aaaaa-aa" })'

# With file
icp canister install backend --args args/init.did
```

### Configuration in icp.yaml

Point to argument values in configuration:

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    init_args: "(record { admin = principal \"aaaaa-aa\" })"
```

### When to Use Each Format

**Candid IDL:**
- Human-readable arguments
- Type-safe with Candid type checking
- Complex nested structures
- Development and testing

**Hex-encoded:**
- Binary data
- Compact representation
- Programmatically generated arguments
- CI/CD pipelines

**File-based:**
- Reusable argument configurations
- Complex multi-line arguments
- Avoiding shell escaping issues
- Version-controlled initialization data

## Complete Example

```yaml
canisters:
  - name: frontend
    recipe:
      type: "@dfinity/asset-canister@v2.1.0"
      configuration:
        dir: dist
    settings:
      memory_allocation: 1073741824

  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    settings:
      compute_allocation: 5
    init_args: "(record { admin = principal \"aaaaa-aa\" })"

networks:
  - name: local
    mode: managed
    gateway:
      port: 9999

environments:
  - name: staging
    network: ic
    canisters: [frontend, backend]
    settings:
      backend:
        compute_allocation: 10
        environment_variables:
          ENV: "staging"

  - name: production
    network: ic
    canisters: [frontend, backend]
    settings:
      frontend:
        memory_allocation: 4294967296
      backend:
        compute_allocation: 30
        freezing_threshold: 7776000
        environment_variables:
          ENV: "production"
    init_args:
      backend: "(record { admin = principal \"xxxx-xxxx\" })"
```

## Sources

Comprehensive ICP CLI documentation:

- ICP CLI Documentation: https://dfinity.github.io/icp-cli/0.1/
- Quickstart: https://dfinity.github.io/icp-cli/0.1/quickstart/
- Tutorial: https://dfinity.github.io/icp-cli/0.1/tutorial/
- Recipes Guide: https://dfinity.github.io/icp-cli/0.1/guides/using-recipes/
- Creating Recipes: https://dfinity.github.io/icp-cli/0.1/guides/creating-recipes/
- Environments Guide: https://dfinity.github.io/icp-cli/0.1/guides/managing-environments/
- Mainnet Deployment: https://dfinity.github.io/icp-cli/0.1/guides/deploying-to-mainnet/
- Deploying to Subnets: https://dfinity.github.io/icp-cli/0.1/guides/deploying-to-specific-subnets/
- Containerized Networks: https://dfinity.github.io/icp-cli/0.1/guides/containerized-networks/
- Managing Identities: https://dfinity.github.io/icp-cli/0.1/guides/managing-identities/
- Tokens and Cycles: https://dfinity.github.io/icp-cli/0.1/guides/tokens-and-cycles/
- CLI Reference: https://dfinity.github.io/icp-cli/0.1/reference/cli/
- Configuration Reference: https://dfinity.github.io/icp-cli/0.1/reference/configuration/
- Canister Settings: https://dfinity.github.io/icp-cli/0.1/reference/canister-settings/
- Environment Variables: https://dfinity.github.io/icp-cli/0.1/reference/environment-variables/
- Releases: https://github.com/dfinity/icp-cli/releases
- Forum Announcement: https://forum.dfinity.org/t/icp-cli-announcements-and-feedback-discussion/60410
- Recipe Repository: https://github.com/dfinity/icp-cli-recipes
