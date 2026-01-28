# ICP CLI Reference

Detailed reference for the ICP CLI recipe system, environment management, containerized networks, configuration, and advanced features.

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

**@dfinity/rust** - Rust canister

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend  # Cargo package name
```

**@dfinity/motoko** - Motoko canister

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/motoko"
      configuration:
        main: src/main.mo  # Main Motoko file
```

**@dfinity/asset-canister** - Frontend assets

```yaml
canisters:
  frontend:
    type: recipe
    recipe:
      type: "@dfinity/asset-canister"
      configuration:
        dir: dist  # Directory containing built assets
```

**@dfinity/prebuilt** - Pre-built WASM module

```yaml
canisters:
  prebuilt:
    type: recipe
    recipe:
      type: "@dfinity/prebuilt"
      configuration:
        path: ./target/wasm32-unknown-unknown/release/canister.wasm
        sha256: "abc123..."  # SHA-256 hash for integrity verification
```

### Recipe Shorthand

The `@dfinity/` shorthand automatically resolves to the latest version from GitHub releases:

```
@dfinity/rust
```

is equivalent to:

```
https://github.com/dfinity/icp-cli-recipes/releases/download/rust-latest/recipe.hbs
```

### Version Pinning

Pin to specific recipe versions for reproducible builds:

```yaml
recipe:
  type: "@dfinity/rust@v3.0.0"  # Locked to v3.0.0
  configuration:
    package: backend
```

Version pinning is recommended for:
- Production deployments
- Team projects requiring build reproducibility
- CI/CD pipelines

### Local Recipes

Use project-specific Handlebars templates for custom build workflows:

```yaml
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
- **@dfinity/motoko**: `main` (main Motoko file path)
- **@dfinity/asset-canister**: `dir` (asset directory)
- **@dfinity/prebuilt**: `path` (WASM file), `sha256` (integrity hash)

Custom recipes may define arbitrary configuration fields.

### Combining Recipes with Settings

Recipes define only build and sync configuration. Add canister settings separately:

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    settings:
      compute_allocation: 10
      memory_allocation: 1GB
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

**BREAKING CHANGE (beta.5)**: "mainnet" environment renamed to "ic". Use `-e ic` instead of `--mainnet` flag.

### Custom Environments

Define custom environments in `icp.yaml`:

```yaml
environments:
  staging:
    network: ic
    settings:
      compute_allocation: 5  # Lower allocation for staging
  production:
    network: ic
    settings:
      compute_allocation: 20  # Higher for production
      memory_allocation: 2GB
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
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    settings:
      compute_allocation: 10  # Default

environments:
  production:
    network: ic
    canisters:
      backend:
        settings:
          compute_allocation: 50  # Override for production
          memory_allocation: 4GB
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
icp canister status -e <environment>
icp canister call -e <environment> <canister> <method>
```

### Multi-Stage Deployment Workflow

Standard workflow for promoting changes:

1. **Develop locally**: `icp deploy` (defaults to local environment)
2. **Test in staging**: `icp deploy -e staging`
3. **Promote to production**: `icp deploy -e production`

Each stage uses different canister IDs and can have different resource allocations.

## Containerized Networks

### What Are Containerized Networks?

Containerized networks run the PocketIC replica in Docker containers, providing isolated, reproducible local networks. Unlike managed networks (default), containerized networks:

- Run in complete isolation from other projects
- Allow multiple networks simultaneously
- Are ideal for CI/CD pipelines
- Provide reproducible environments

### Benefits

- **Isolation**: Each project has its own network instance
- **Multiple instances**: Run multiple local networks in parallel
- **CI/CD ready**: Docker-based networks work in containerized build environments
- **Reproducibility**: Same network configuration across machines

### Configuration

Define in `icp.yaml`:

```yaml
networks:
  local:
    type: containerized
    container:
      image: ghcr.io/dfinity/pocketic:latest
      ports:
        - "8000:8000"  # Replica API
```

### Security (Beta.5 Improvement)

Networks now bind to `127.0.0.1` by default, preventing external network access:

```yaml
networks:
  local:
    type: containerized
    container:
      ports:
        - "127.0.0.1:8000:8000"  # Binds only to localhost
```

### Platform Requirements

**Windows:**
- Docker Desktop is **required** for local networks (both managed and containerized)
- Native Rust canister support
- Motoko canisters require WSL (Motoko compiler doesn't run on Windows)

**macOS/Linux:**
- Native support for all canister types
- Docker required only for containerized networks (optional for managed networks)

### IC Network Configuration

When using the `ic` environment, configure IC-specific options:

```yaml
networks:
  ic:
    ii: true              # Enable Internet Identity
    nns: true             # Enable Network Nervous System
    subnets: 2            # Number of subnets
    artificial-delay-ms: 100  # Simulate network latency
```

These options are useful for local testing that simulates IC mainnet behavior.

### When to Use Containerized Networks

**Use containerized networks when:**
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
canisters:    # Canister definitions
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend

networks:     # Network definitions
  local:
    type: managed

environments: # Environment definitions
  production:
    network: ic
```

### Canister Configuration with Recipes

Recipe-based canister definition:

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"           # Recipe type
      configuration:                  # Recipe-specific config
        package: backend
    settings:                         # Canister settings (separate)
      compute_allocation: 10
```

### Recipe Configuration Examples

**Rust canister:**

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend  # Matches Cargo.toml package name
```

**Motoko canister:**

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/motoko"
      configuration:
        main: src/backend/main.mo  # Path to main Motoko file
```

**Asset canister:**

```yaml
canisters:
  frontend:
    type: recipe
    recipe:
      type: "@dfinity/asset-canister"
      configuration:
        dir: dist  # Directory with built frontend assets
```

**Prebuilt WASM:**

```yaml
canisters:
  prebuilt:
    type: recipe
    recipe:
      type: "@dfinity/prebuilt"
      configuration:
        path: ./custom.wasm
        sha256: "abc123def456..."  # SHA-256 hash for integrity
```

### External File References

Reference external files for arguments:

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    install_args: args/backend_init.did  # Candid init arguments
```

### Glob Patterns for Sources

Use glob patterns to specify source files:

```yaml
sources:
  - "src/**/*.rs"
  - "Cargo.toml"
  - "Cargo.lock"
```

### Modular Project Organization

Import configuration from external files:

```yaml
# icp.yaml
import:
  - canisters/backend.yaml
  - canisters/frontend.yaml
```

```yaml
# canisters/backend.yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
```

### Build Configuration

Recipes handle build configuration automatically. For manual builds:

```yaml
canisters:
  custom:
    build:
      - script: cargo build --release --target wasm32-unknown-unknown
      - script: ic-wasm target/wasm32-unknown-unknown/release/custom.wasm -o custom_optimized.wasm
    wasm: custom_optimized.wasm
```

### Sync Steps for Asset Uploads

Asset canisters use sync steps to upload files:

```yaml
canisters:
  frontend:
    type: recipe
    recipe:
      type: "@dfinity/asset-canister"
      configuration:
        dir: dist  # Recipe handles sync automatically
```

### Environment Variables in Settings

Pass environment variables to canisters:

```yaml
canisters:
  backend:
    settings:
      environment_variables:
        - name: API_KEY
          value: "secret-key"
        - name: LOG_LEVEL
          value: "debug"
```

### install_args Configuration

Point to argument files for canister initialization:

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    install_args: args/init.did  # Candid format
```

Or use hex format:

```yaml
canisters:
  backend:
    install_args: args/init.hex  # Hex-encoded arguments
```

### Combining Recipes with Settings

Recipes define build/sync configuration. Settings are defined separately:

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    settings:                    # Separate from recipe
      compute_allocation: 20
      memory_allocation: 2GB
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
  memory_allocation: 2GB              # Max memory (bytes or human-readable)
  freezing_threshold: 2592000         # Seconds (default: 30 days)
  reserved_cycles_limit: 5T           # Max cycles reserved
  wasm_memory_limit: 3GB              # Max WASM memory
  log_visibility: controllers         # Who can read logs (public/controllers)
  environment_variables:              # Environment variables
    - name: VAR_NAME
      value: "value"
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

Maximum memory the canister can use. Specified in bytes or human-readable format:

```yaml
settings:
  memory_allocation: 4GB  # 4 gigabytes maximum
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
  reserved_cycles_limit: 10T  # 10 trillion cycles
```

### WASM Memory Limit

Maximum memory available to WASM execution:

```yaml
settings:
  wasm_memory_limit: 3GB
```

### Log Visibility

Control who can read canister logs:

```yaml
settings:
  log_visibility: public      # Anyone can read logs
  # OR
  log_visibility: controllers # Only controllers can read logs
```

### Setting at Canister vs Environment Level

**Canister level** (applies to all environments):

```yaml
canisters:
  backend:
    settings:
      compute_allocation: 10
```

**Environment level** (overrides canister settings):

```yaml
environments:
  production:
    canisters:
      backend:
        settings:
          compute_allocation: 50  # Production gets more compute
```

### Subnet Selection

Deploy to specific subnet during creation:

```bash
icp canister create --subnet <subnet-id>
```

Or specify in `icp.yaml`:

```yaml
canisters:
  backend:
    subnet: <subnet-id>
```

### Settings Commands

Show current settings:

```bash
icp canister settings show <canister>
```

Update settings:

```bash
icp canister settings update <canister> --compute-allocation 20
```

Sync settings from YAML:

```bash
icp canister settings sync <canister>
```

## Argument Handling

### File-Based Arguments (NEW in Beta.5)

Pass complex arguments via files instead of command line.

**Candid IDL format:**

```bash
icp canister call backend init --argument-file args/init.did
```

```candid
// args/init.did
(record {
  name = "My Canister";
  max_users = 1000 : nat64;
})
```

**Hex format:**

```bash
icp canister install backend --argument-file args/init.hex
```

```
4449444C...
```

### Hex-Encoded Arguments

Pass hex-encoded arguments directly:

```bash
icp canister call backend method --argument 4449444C0001710B48656C6C6F20576F726C64
```

Useful for:
- Binary data
- Compact representation
- Arguments generated programmatically

### Configuration in icp.yaml

Point to argument files in configuration:

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    install_args: args/init.did  # Candid format
```

Or hex format:

```yaml
canisters:
  backend:
    install_args: args/init.hex  # Hex-encoded
```

### When to Use Each Format

**Candid IDL (`.did` files):**
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

## Sources

Comprehensive ICP CLI documentation:

- ICP CLI Documentation: https://dfinity.github.io/icp-cli/
- Quickstart: https://dfinity.github.io/icp-cli/quickstart/
- Tutorial: https://dfinity.github.io/icp-cli/tutorial/
- Recipes Guide: https://dfinity.github.io/icp-cli/guides/using-recipes/
- Creating Recipes: https://dfinity.github.io/icp-cli/guides/creating-recipes/
- Environments Guide: https://dfinity.github.io/icp-cli/guides/managing-environments/
- Mainnet Deployment: https://dfinity.github.io/icp-cli/guides/deploying-to-mainnet/
- Containerized Networks: https://dfinity.github.io/icp-cli/guides/containerized-networks/
- Managing Identities: https://dfinity.github.io/icp-cli/guides/managing-identities/
- Tokens and Cycles: https://dfinity.github.io/icp-cli/guides/tokens-and-cycles/
- CLI Reference: https://dfinity.github.io/icp-cli/reference/cli/
- Configuration Reference: https://dfinity.github.io/icp-cli/reference/configuration/
- Canister Settings: https://dfinity.github.io/icp-cli/reference/canister-settings/
- Beta Releases: https://github.com/dfinity/icp-cli/releases
- Forum Announcement: https://forum.dfinity.org/t/first-beta-release-of-icp-cli/60410
- Recipe Repository: https://github.com/dfinity/icp-cli-recipes
