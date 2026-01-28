# ICP CLI Examples

Practical workflow examples for common ICP CLI tasks.

## Recipe-Based Project Creation

### Rust Canister with @dfinity/rust Recipe

Create a Rust backend canister using the official recipe:

```bash
# Create project directory
mkdir my-project
cd my-project

# Create icp.yaml with Rust recipe
cat > icp.yaml << 'EOF'
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend  # Matches Cargo.toml package name
EOF

# Create Rust canister code
cargo new --lib backend
cd backend
# Edit Cargo.toml and src/lib.rs as needed
cd ..

# Deploy
icp network start -d
icp deploy
```

**Note for Windows users:** Rust canisters are fully supported on native Windows. Ensure Docker Desktop is running for local networks.

### Motoko Canister with @dfinity/motoko Recipe

Create a Motoko backend canister:

```bash
mkdir my-project
cd my-project

cat > icp.yaml << 'EOF'
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/motoko"
      configuration:
        main: src/main.mo
EOF

# Create Motoko source
mkdir -p src
cat > src/main.mo << 'EOF'
actor {
  public query func greet(name : Text) : async Text {
    "Hello, " # name # "!"
  };
}
EOF

icp network start -d
icp deploy
icp canister call backend greet '("World")'
```

**Note for Windows users:** Motoko canisters require WSL (Windows Subsystem for Linux). Install icp-cli inside WSL for Motoko development.

### Asset Canister with @dfinity/asset-canister Recipe

Create a frontend asset canister:

```bash
mkdir my-project
cd my-project

cat > icp.yaml << 'EOF'
canisters:
  frontend:
    type: recipe
    recipe:
      type: "@dfinity/asset-canister"
      configuration:
        dir: dist  # Directory containing built assets
EOF

# Build frontend (example with React)
npx create-react-app frontend
cd frontend
npm run build
cd ..

# Move built assets to dist/
mv frontend/build dist

icp network start -d
icp deploy
```

The recipe automatically handles asset synchronization to the canister.

### Prebuilt WASM with @dfinity/prebuilt Recipe

Use a pre-built WASM module:

```bash
mkdir my-project
cd my-project

# Generate SHA-256 hash of WASM file
sha256sum custom.wasm
# Output: abc123def456... custom.wasm

cat > icp.yaml << 'EOF'
canisters:
  prebuilt:
    type: recipe
    recipe:
      type: "@dfinity/prebuilt"
      configuration:
        path: ./custom.wasm
        sha256: "abc123def456..."  # From sha256sum output
EOF

icp network start -d
icp deploy
```

### Multi-Canister Project with Mixed Recipes

Combine multiple canister types in one project:

```yaml
# icp.yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    settings:
      compute_allocation: 20
      memory_allocation: 2GB

  frontend:
    type: recipe
    recipe:
      type: "@dfinity/asset-canister"
      configuration:
        dir: dist

  motoko_service:
    type: recipe
    recipe:
      type: "@dfinity/motoko"
      configuration:
        main: src/service.mo
```

Deploy all canisters:

```bash
icp network start -d
icp deploy  # Deploys all three canisters
```

### Recipe Versioning Example

Pin to specific recipe version for reproducible builds:

```yaml
# icp.yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust@v3.0.0"  # Pinned to v3.0.0
      configuration:
        package: backend
```

Recommended for production deployments and CI/CD pipelines.

### Local Recipe File

Use a project-specific custom recipe:

```bash
mkdir -p recipes

cat > recipes/custom-rust.hbs << 'EOF'
build:
  - script: cargo build --release --target wasm32-unknown-unknown
  - script: ic-wasm optimize ./target/wasm32-unknown-unknown/release/{{package}}.wasm -o {{package}}_optimized.wasm
wasm: {{package}}_optimized.wasm
EOF

cat > icp.yaml << 'EOF'
canisters:
  backend:
    type: recipe
    recipe:
      type: "file://recipes/custom-rust.hbs"
      configuration:
        package: backend
EOF
```

### Remote Recipe with SHA-256

Use a recipe from a custom URL:

```yaml
# icp.yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "https://example.com/recipes/my-recipe.hbs"
      sha256: "abc123..."  # Required for integrity verification
      configuration:
        custom_option: value
```

### Viewing Expanded Config

After defining recipes, view the full expanded configuration:

```bash
icp project show
```

This displays the complete YAML after recipe template expansion, useful for debugging and understanding what the recipe generates.

## Multi-Environment Deployment

### Complete Multi-Stage Workflow

Develop locally, test in staging, promote to production:

```bash
# 1. Develop locally
icp network start -d
icp deploy  # Defaults to local environment
icp canister call backend greet '("World")'
icp canister status backend  # Check local canister

# 2. Deploy to staging (custom environment)
icp deploy -e staging
icp canister status -e staging backend
icp canister call -e staging backend greet '("Staging")'

# 3. Promote to IC mainnet
# IMPORTANT: Use -e ic (not --mainnet, which was removed in beta.5)
icp deploy -e ic
icp canister status -e ic backend
icp canister call -e ic backend greet '("Production")'
```

### Environment Configuration in icp.yaml

Define staging and production environments:

```yaml
# icp.yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    settings:
      compute_allocation: 10  # Default allocation

environments:
  staging:
    network: ic
    canisters:
      backend:
        settings:
          compute_allocation: 20  # More resources for staging tests
          memory_allocation: 2GB

  production:
    network: ic
    canisters:
      backend:
        settings:
          compute_allocation: 50  # Maximum resources for production
          memory_allocation: 4GB
          freezing_threshold: 7776000  # 90 days
```

### Environment-Specific Settings

Different resource allocations per environment:

```yaml
# icp.yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    settings:
      compute_allocation: 5      # Local default
      memory_allocation: 512MB

environments:
  ic:  # IC mainnet environment
    canisters:
      backend:
        settings:
          compute_allocation: 30    # Production allocation
          memory_allocation: 3GB
          controllers:
            - aaaaa-aa               # Production controller
          log_visibility: controllers  # Restrict logs
```

### Canister ID Management Across Environments

Canister IDs are stored per-environment:

```
.icp/
  local/
    canister_ids.json     # {"backend": "rrkah-fqaaa-aaaaa-aaaaq-cai"}
  staging/
    canister_ids.json     # {"backend": "ryjl3-tyaaa-aaaaa-aaaba-cai"}
  production/
    canister_ids.json     # {"backend": "r7inp-6aaaa-aaaaa-aaabq-cai"}
```

Commit environment-specific `canister_ids.json` to preserve IDs.

### Environment-Specific Argument Files

Use different initialization arguments per environment:

```yaml
# icp.yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    install_args: args/local_init.did  # Default for local

environments:
  staging:
    canisters:
      backend:
        install_args: args/staging_init.did

  production:
    canisters:
      backend:
        install_args: args/production_init.did
```

```candid
// args/production_init.did
(record {
  max_users = 100000 : nat64;
  log_level = "error";
  api_endpoint = "https://api.production.example.com";
})
```

### Checking Environment Status

List all environments:

```bash
icp environment list
```

Check canister status in specific environment:

```bash
icp canister status -e staging backend
icp canister status -e ic backend  # IC mainnet (not --mainnet)
```

### Migration Between Environments

Deploy same canister across environments while preserving IDs:

```bash
# Deploy to local first
icp deploy

# Create canister on IC without installing
icp canister create -e ic backend

# Deploy (install) to IC
icp deploy -e ic backend

# Canister IDs are now tracked in both environments
```

## Containerized Network Setup

### Docker-Based Network Configuration

Configure a containerized local network in `icp.yaml`:

```yaml
# icp.yaml
networks:
  local:
    type: containerized
    container:
      image: ghcr.io/dfinity/pocketic:latest
      ports:
        - "127.0.0.1:8000:8000"  # Binds to localhost only (secure)

canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
```

Start the containerized network:

```bash
icp network start -d
```

**Windows requirement:** Docker Desktop must be installed and running. Local networks (both managed and containerized) require Docker Desktop on Windows.

### Network Security (Beta.5 Improvement)

Networks now bind to `127.0.0.1` by default, preventing external access:

```yaml
networks:
  local:
    type: containerized
    container:
      ports:
        - "127.0.0.1:8000:8000"  # Only accessible from localhost
```

This prevents accidental exposure of local development networks.

### Multiple Isolated Networks

Run multiple projects with isolated networks simultaneously:

```yaml
# project1/icp.yaml
networks:
  local:
    type: containerized
    container:
      image: ghcr.io/dfinity/pocketic:latest
      ports:
        - "127.0.0.1:8001:8000"  # Port 8001
```

```yaml
# project2/icp.yaml
networks:
  local:
    type: containerized
    container:
      image: ghcr.io/dfinity/pocketic:latest
      ports:
        - "127.0.0.1:8002:8000"  # Port 8002 (different)
```

Both networks can run simultaneously without conflicts.

### IC Network Configuration Options

Simulate IC mainnet behavior locally:

```yaml
networks:
  local:
    type: containerized
    container:
      image: ghcr.io/dfinity/pocketic:latest
      ports:
        - "127.0.0.1:8000:8000"
    ii: true                    # Enable Internet Identity
    nns: true                   # Enable Network Nervous System
    subnets: 4                  # Simulate 4 subnets
    artificial-delay-ms: 50     # 50ms network latency simulation
```

Useful for testing realistic IC behavior locally.

## Advanced Canister Configuration

### Setting Compute Allocation and Memory

Configure resource limits in `icp.yaml`:

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    settings:
      compute_allocation: 30      # 30% compute guarantee
      memory_allocation: 3GB      # 3 GB maximum memory
      freezing_threshold: 7776000 # 90 days (in seconds)
```

Deploy with settings:

```bash
icp deploy
```

Update settings for existing canister:

```bash
icp canister settings update backend --compute-allocation 50
icp canister settings update backend --memory-allocation 4GB
```

### Deploying to Specific Subnet

Deploy canister to a specific subnet:

```bash
icp canister create backend --subnet <subnet-id>
icp canister install backend
```

Or specify in `icp.yaml`:

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    subnet: <subnet-id>
```

### Configuring Log Visibility and Environment Variables

```yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    settings:
      log_visibility: controllers  # Only controllers can read logs
      environment_variables:
        - name: API_KEY
          value: "secret-key"
        - name: LOG_LEVEL
          value: "info"
        - name: MAX_CONNECTIONS
          value: "100"
```

### Controller Safety (Beta.5 Feature)

CLI warns before removing yourself from controllers:

```bash
icp canister settings update backend --controllers aaaaa-aa

# Warning: You are about to remove yourself from the controllers.
# This will prevent you from managing this canister.
# Continue? [y/N]
```

Skip confirmation in scripts with `--force`:

```bash
icp canister settings update backend --controllers aaaaa-aa --force
```

**Important:** Never accidentally lock yourself out of a canister. Review controller changes carefully.

### Reading Canister Metadata

Read specific metadata sections from canisters:

```bash
icp canister metadata backend candid:service
icp canister metadata backend icp:public
icp canister metadata backend icp:private
```

New in beta.5: `canister metadata` command for accessing canister metadata sections.

### Canister Status Showing Name (Beta.5 Improvement)

Canister status now displays the canister name:

```bash
icp canister status backend

# Output includes:
# Canister: backend
# Status: Running
# Module hash: 0xabc123...
# Controllers: [...]
# Memory size: 1.2 MB
# Cycles: 5.3 T
```

### Large WASM Deployment (Beta.5 Feature)

WASM modules larger than 2MB are automatically uploaded in chunks:

```bash
icp canister install backend
# Automatically uses chunked upload if backend.wasm > 2MB
# No manual action required
```

This happens transparently. You don't need to do anything special for large WASM files.

## Identity Management

### Creating Keyring-Backed Identity

Keyring storage is the most secure option (uses OS keychain):

```bash
icp identity new my-identity --storage-mode keyring
icp identity use my-identity
```

Default for production use.

### Importing from PEM File

Import existing identity from PEM:

```bash
icp identity import production-identity ./production.pem --storage-mode keyring
icp identity use production-identity
```

### Exporting for Backup

Export identity for backup (creates PEM file):

```bash
icp identity export my-identity > backup.pem
# Store backup.pem securely offline
```

### Password-Protected Identity for CI/CD

Create password-protected identity for automated environments:

```bash
icp identity new ci-identity --storage-mode password-protected
# Enter password when prompted

# Use in CI with password file
echo "password" > password.txt
ICP_IDENTITY_PASSWORD_FILE=password.txt icp deploy -e ic
```

### Getting Ledger Account ID (Beta.5 Feature)

Get your ICP ledger AccountIdentifier:

```bash
icp identity account-id
# Output: d4685b31b51450508aff0331584df7692a84467b680326f5c5f7d30ae711682f
```

This displays the AccountIdentifier hex string for ICP ledger transfers.

### Using AccountIdentifier for Transfers

Transfer ICP tokens using AccountIdentifier:

```bash
icp token transfer --to d4685b31b51450508aff0331584df7692a84467b680326f5c5f7d30ae711682f --amount 1.5
```

Beta.5 supports AccountIdentifier hex strings directly.

## Cycles Management

### Checking Cycles Balance

Check your cycles wallet balance:

```bash
icp cycles balance
# Output: 15.2 T cycles
```

Human-readable output (T = trillion).

### Top-Up with Human-Readable Amounts (Beta.5 Feature)

Top-up canister using human-friendly formats:

```bash
# Using trillion (T)
icp canister top-up --amount 2T backend

# Using billion (b or B)
icp canister top-up --amount 500b backend

# Using million (m or M)
icp canister top-up --amount 1.5m backend

# Using thousand (k or K)
icp canister top-up --amount 100k backend

# Using underscores for readability
icp canister top-up --amount 2_000_000_000_000 backend
```

Supported formats (NEW in beta.5):
- `1_000` (underscores)
- `1k` or `1K` (thousand)
- `1.5m` or `1.5M` (million)
- `1_234.5b` or `1_234.5B` (billion)
- `4T` (trillion)

### Minting Cycles

Mint cycles from ICP tokens:

```bash
# Mint 5.0 ICP worth of cycles
icp cycles mint --amount 5.0
```

### Transferring Cycles (Beta.5 NEW Command)

Transfer cycles to another canister:

```bash
# NEW command (replaces 'icp token cycles transfer')
icp cycles transfer --to rrkah-fqaaa-aaaaa-aaaaq-cai --amount 2T

# Human-readable amounts supported
icp cycles transfer --to rrkah-fqaaa-aaaaa-aaaaq-cai --amount 500m
```

**BREAKING CHANGE (beta.5):** The old `icp token cycles transfer` command has been replaced with `icp cycles transfer`.

### Token Transfers with AccountIdentifier

Transfer ICP tokens using AccountIdentifier hex strings:

```bash
icp token transfer \
  --to d4685b31b51450508aff0331584df7692a84467b680326f5c5f7d30ae711682f \
  --amount 10.5
```

Beta.5 accepts AccountIdentifier hex strings for transfers.

## Argument Handling Examples

### File-Based Candid Arguments

Create argument file in Candid IDL format:

```candid
// args/init.did
(record {
  name = "My Service";
  max_users = 1000 : nat64;
  admins = vec {
    principal "aaaaa-aa";
    principal "bbbbb-bb";
  };
})
```

Use with canister call:

```bash
icp canister call backend init --argument-file args/init.did
```

Use with canister install:

```bash
icp canister install backend --argument-file args/init.did
```

### File-Based Hex Arguments

Create hex-encoded argument file:

```
4449444C016D016C02007101781768656C6C6F20776F726C640100
```

Use with canister operations:

```bash
icp canister install backend --argument-file args/init.hex
```

### Direct Hex-Encoded Arguments

Pass hex-encoded arguments directly on command line:

```bash
icp canister call backend method --argument 4449444C0001710B48656C6C6F20576F726C64
```

### Configuring install_args in icp.yaml

Point to argument files in configuration:

```yaml
# icp.yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend
    install_args: args/init.did  # Candid format

  frontend:
    type: recipe
    recipe:
      type: "@dfinity/asset-canister"
      configuration:
        dir: dist
    install_args: args/frontend_init.hex  # Hex format
```

Deploy uses the specified argument files automatically:

```bash
icp deploy  # Uses args/init.did for backend, args/frontend_init.hex for frontend
```

### When to Use Each Format

**Candid IDL (`.did` files):**
- Development and testing (human-readable)
- Complex nested structures
- Type-safe argument validation
- Documentation purposes

**Hex-encoded:**
- Binary data
- Programmatically generated arguments
- CI/CD pipelines (compact, no escaping issues)
- Production deployments

**File-based (both formats):**
- Reusable configurations
- Version-controlled initialization data
- Avoiding shell escaping problems
- Multi-line complex arguments
