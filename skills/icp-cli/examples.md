# ICP CLI Examples

Practical workflow examples for common ICP CLI v0.1.0 tasks.

## Recipe-Based Project Creation

### Rust Canister with @dfinity/rust Recipe

Create a Rust backend canister using the official recipe:

```bash
# Create project directory
mkdir my-project
cd my-project

# Create icp.yaml with Rust recipe (version required)
cat > icp.yaml << 'EOF'
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
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
  - name: backend
    recipe:
      type: "@dfinity/motoko@v4.0.0"
      configuration:
        main: src/main.mo
        args: ""  # Required in v4.0.0 (moc compiler flags, will become optional)
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
  - name: frontend
    recipe:
      type: "@dfinity/asset-canister@v2.1.0"
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
  - name: prebuilt
    recipe:
      type: "@dfinity/prebuilt@v2.0.0"
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
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    settings:
      compute_allocation: 20
      memory_allocation: 2147483648

  - name: frontend
    recipe:
      type: "@dfinity/asset-canister@v2.1.0"
      configuration:
        dir: dist

  - name: motoko_service
    recipe:
      type: "@dfinity/motoko@v4.0.0"
      configuration:
        main: src/service.mo
        args: ""
```

Deploy all canisters:

```bash
icp network start -d
icp deploy  # Deploys all three canisters
```

### Local Recipe File

Use a project-specific custom recipe:

```bash
mkdir -p recipes

cat > recipes/custom-rust.hbs << 'EOF'
build:
  steps:
    - type: script
      commands:
        - cargo build --release --target wasm32-unknown-unknown
        - ic-wasm optimize ./target/wasm32-unknown-unknown/release/{{package}}.wasm -o {{package}}_optimized.wasm
        - cp {{package}}_optimized.wasm "$ICP_WASM_OUTPUT_PATH"
EOF

cat > icp.yaml << 'EOF'
canisters:
  - name: backend
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
  - name: backend
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
icp canister status backend -e staging
icp canister call backend greet '("Staging")' -e staging

# 3. Promote to IC mainnet
# IMPORTANT: Use -e ic (not --mainnet)
icp deploy -e ic
icp canister status backend -e ic
icp canister call backend greet '("Production")' -e ic
```

### Environment Configuration in icp.yaml

Define staging and production environments:

```yaml
# icp.yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    settings:
      compute_allocation: 10  # Default allocation

environments:
  - name: staging
    network: ic
    canisters: [backend]
    settings:
      backend:
        compute_allocation: 20  # More resources for staging tests
        memory_allocation: 2147483648

  - name: production
    network: ic
    canisters: [backend]
    settings:
      backend:
        compute_allocation: 50  # Maximum resources for production
        memory_allocation: 4294967296
        freezing_threshold: 7776000  # 90 days
```

### Environment-Specific Settings

Different resource allocations per environment:

```yaml
# icp.yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    settings:
      compute_allocation: 5      # Local default

environments:
  - name: ic
    canisters: [backend]
    settings:
      backend:
        compute_allocation: 30    # Production allocation
        memory_allocation: 3221225472
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

### Environment-Specific Initialization Arguments

Use different initialization arguments per environment:

```yaml
# icp.yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    init_args: "(record { mode = \"local\" })"

environments:
  - name: staging
    network: ic
    canisters: [backend]
    init_args:
      backend: "(record { mode = \"staging\" })"

  - name: production
    network: ic
    canisters: [backend]
    init_args:
      backend: "(record { mode = \"production\" })"
```

### Checking Environment Status

List all environments:

```bash
icp environment list
```

Check canister status in specific environment:

```bash
icp canister status backend -e staging
icp canister status backend -e ic  # IC mainnet (not --mainnet)
```

### Migration Between Environments

Deploy same canister across environments while preserving IDs:

```bash
# Deploy to local first
icp deploy

# Create canister on IC without installing
icp canister create backend -e ic

# Deploy (install) to IC
icp deploy -e ic backend

# Canister IDs are now tracked in both environments
```

## Docker Network Setup

### Docker-Based Network Configuration

Configure a Docker-based local network in `icp.yaml`:

```yaml
# icp.yaml
networks:
  - name: local
    mode: managed
    image: ghcr.io/dfinity/icp-cli-network-launcher
    port-mapping:
      - "8000:4943"  # host:container (container uses port 4943)

canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
```

Start the Docker-based network:

```bash
icp network start -d
```

**Windows requirement:** Docker Desktop must be installed and running. Local networks (both managed and Docker-based) require Docker Desktop on Windows.

### Multiple Isolated Networks

Run multiple projects with isolated networks simultaneously:

```yaml
# project1/icp.yaml
networks:
  - name: local
    mode: managed
    image: ghcr.io/dfinity/icp-cli-network-launcher
    port-mapping:
      - "8001:4943"  # Port 8001
```

```yaml
# project2/icp.yaml
networks:
  - name: local
    mode: managed
    image: ghcr.io/dfinity/icp-cli-network-launcher
    port-mapping:
      - "8002:4943"  # Port 8002 (different)
```

Both networks can run simultaneously without conflicts.

### Network Options

Simulate IC mainnet behavior locally:

```yaml
networks:
  - name: local
    mode: managed
    ii: true                    # Enable Internet Identity
    nns: true                   # Enable Network Nervous System
    subnets:                    # Configure subnet types
      - application
      - application
      - application
      - application
    artificial_delay_ms: 50     # 50ms network latency simulation
```

Useful for testing realistic IC behavior locally.

## Advanced Canister Configuration

### Setting Compute Allocation and Memory

Configure resource limits in `icp.yaml`:

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    settings:
      compute_allocation: 30      # 30% compute guarantee
      memory_allocation: 3221225472  # 3 GB maximum memory
      freezing_threshold: 7776000 # 90 days (in seconds)
```

Deploy with settings:

```bash
icp deploy
```

Update settings for existing canister:

```bash
icp canister settings update backend --compute-allocation 50
icp canister settings update backend --memory-allocation 4294967296
```

### Deploying to Specific Subnet

Deploy canister to a specific subnet:

```bash
icp canister create backend --subnet <subnet-id> -e ic
icp canister install backend -e ic
```

### Configuring Log Visibility and Environment Variables

```yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    settings:
      log_visibility: controllers  # Only controllers can read logs
      environment_variables:
        API_KEY: "secret-key"
        LOG_LEVEL: "info"
        MAX_CONNECTIONS: "100"
```

Update log visibility via CLI:

```bash
icp canister settings update backend --log-visibility public
icp canister settings update backend --add-log-viewer <principal>
icp canister settings update backend --remove-log-viewer <principal>
```

### Controller Safety

CLI warns before removing yourself from controllers:

```bash
icp canister settings update backend --set-controller aaaaa-aa

# Warning: You are about to remove yourself from the controllers.
# This will prevent you from managing this canister.
# Continue? [y/N]
```

Skip confirmation in scripts with `--force`:

```bash
icp canister settings update backend --set-controller aaaaa-aa --force
```

**Important:** Never accidentally lock yourself out of a canister. Review controller changes carefully.

### Reading Canister Metadata

Read specific metadata sections from canisters:

```bash
icp canister metadata backend candid:service
icp canister metadata backend icp:public
icp canister metadata backend icp:private
```

### Large WASM Deployment

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
icp identity new my-identity --storage keyring
icp identity default my-identity
```

Default for production use.

### Importing from PEM File

Import existing identity from PEM:

```bash
icp identity import production-identity --from-pem ./production.pem
icp identity default production-identity
```

### Exporting for Backup

Export identity for backup (outputs PEM to stdout):

```bash
icp identity export my-identity > backup.pem
# Store backup.pem securely offline
```

For password-protected identities:

```bash
icp identity export my-identity --password-file ./password.txt > backup.pem
```

### Renaming an Identity

Change the name of an existing identity:

```bash
icp identity rename old-name new-name
```

### Deleting an Identity

Remove an identity you no longer need:

```bash
icp identity delete my-old-identity
```

**Warning:** This permanently deletes the identity. Export a backup first if you might need it later.

### HSM Identity (PKCS#11)

Link a hardware security module identity:

```bash
icp identity link hsm my-hsm-identity \
  --pkcs11-module /usr/local/lib/libsofthsm2.so \
  --slot 0 \
  --key-id 01 \
  --pin-file ./hsm_pin.txt
```

Supported key algorithms: Secp256k1, Prime256v1 (NIST P-256), Ed25519.

### Password-Protected Identity for CI/CD

Create password-protected identity for automated environments:

```bash
icp identity new ci-identity --storage password
# Enter password when prompted

# Use in CI with password file
echo "password" > password.txt
icp deploy --identity ci-identity --identity-password-file password.txt -e ic
```

### Getting Ledger Account ID

Get your ICP ledger AccountIdentifier:

```bash
icp identity account-id
# Output: d4685b31b51450508aff0331584df7692a84467b680326f5c5f7d30ae711682f

# Convert any principal to account ID
icp identity account-id --of-principal aaaaa-aa
```

### Using AccountIdentifier for Transfers

Transfer ICP tokens using AccountIdentifier:

```bash
icp token transfer 1.5 d4685b31b51450508aff0331584df7692a84467b680326f5c5f7d30ae711682f -n ic
```

## Cycles Management

### Checking Cycles Balance

Check your cycles balance:

```bash
icp cycles balance -n ic
# Output: 15.2 T cycles
```

Human-readable output (T = trillion).

### Top-Up with Human-Readable Amounts

Top-up canister using human-friendly formats:

```bash
# Using trillion (T)
icp canister top-up --amount 2T backend -e ic

# Using billion (b or B)
icp canister top-up --amount 500b backend -e ic

# Using million (m or M)
icp canister top-up --amount 1.5m backend -e ic

# Using thousand (k or K)
icp canister top-up --amount 100k backend -e ic

# Using underscores for readability
icp canister top-up --amount 2_000_000_000_000 backend -e ic
```

Supported formats:
- `1_000` (underscores)
- `1k` or `1K` (thousand)
- `1.5m` or `1.5M` (million)
- `1_234.5b` or `1_234.5B` (billion)
- `4T` (trillion)

### Converting ICP to Cycles

Convert ICP tokens to cycles:

```bash
# Convert a specific amount of ICP
icp cycles mint --icp 5 -n ic

# Or request a specific amount of cycles
icp cycles mint --cycles 5T -n ic
```

### Transferring Cycles

Transfer cycles to another principal (positional args: amount, receiver):

```bash
# Transfer 2 trillion cycles
icp cycles transfer 2T rrkah-fqaaa-aaaaa-aaaaq-cai -n ic

# Human-readable amounts supported
icp cycles transfer 500m rrkah-fqaaa-aaaaa-aaaaq-cai -n ic
```

### Token Transfers

Transfer ICP tokens (positional args: amount, receiver):

```bash
icp token transfer 10.5 d4685b31b51450508aff0331584df7692a84467b680326f5c5f7d30ae711682f -n ic
```

### ICRC-1 Token Operations

Work with any ICRC-1 token by specifying the ledger canister ID:

```bash
# Check ckBTC balance
icp token mxzaz-hqaaa-aaaar-qaada-cai balance -n ic

# Transfer ckBTC
icp token mxzaz-hqaaa-aaaar-qaada-cai transfer 0.001 xxxxx-xxxxx-xxxxx-xxxxx-cai -n ic
```

## Argument Handling Examples

### Candid Arguments

Pass Candid text directly:

```bash
icp canister call backend init '(record { name = "My Service"; max_users = 1000 : nat64 })'
```

### File-Based Arguments

Create argument file in Candid format:

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

Use with canister call (file path as positional argument):

```bash
icp canister call backend init args/init.did
```

Use with canister install:

```bash
icp canister install backend --args args/init.did
```

### Hex-Encoded Arguments

Pass hex-encoded arguments directly:

```bash
icp canister call backend method 4449444C0001710B48656C6C6F20576F726C64
```

### Configuring init_args in icp.yaml

Point to argument values in configuration:

```yaml
# icp.yaml
canisters:
  - name: backend
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend
    init_args: "(record { admin = principal \"aaaaa-aa\" })"
```

Deploy uses the specified arguments automatically:

```bash
icp deploy  # Uses init_args for backend
```

### When to Use Each Format

**Candid IDL:**
- Development and testing (human-readable)
- Complex nested structures
- Type-safe argument validation

**Hex-encoded:**
- Binary data
- Programmatically generated arguments
- CI/CD pipelines (compact, no escaping issues)

**File-based:**
- Reusable configurations
- Version-controlled initialization data
- Avoiding shell escaping problems
- Multi-line complex arguments
