# ICP CLI Best Practices

Security, resource management, and operational best practices for ICP CLI.

## Recipe Usage Patterns

### When to Use Official Recipes

Use `@dfinity/` official recipes for:

- **Standard canister types**: Rust, Motoko, asset canisters
- **Best practices**: Recipes encapsulate DFINITY's recommended build patterns
- **Team consistency**: Same recipe across projects ensures uniform configuration
- **Maintenance**: Recipe updates propagate automatically (if not version-pinned)

Official recipes:
- `@dfinity/rust` - Rust canisters
- `@dfinity/motoko` - Motoko canisters
- `@dfinity/asset-canister` - Frontend assets
- `@dfinity/prebuilt` - Pre-built WASM modules

### When to Use Custom Configuration

Use manual configuration (no recipes) for:

- **Very simple projects**: Where recipe overhead isn't justified
- **Highly custom workflows**: Unique build processes not covered by recipes
- **Learning purposes**: Understanding how build configuration works
- **One-off experiments**: Prototypes that won't be maintained

### Version Pinning for Reproducibility

Always pin recipe versions for production:

```yaml
# Good: Pinned version
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust@v3.0.0"  # Explicit version
      configuration:
        package: backend
```

```yaml
# Risky: Latest version (development only)
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"  # Unpinned (uses latest)
      configuration:
        package: backend
```

**Use unpinned for:**
- Local development
- Exploratory projects
- Getting latest features

**Use pinned for:**
- Production deployments
- CI/CD pipelines
- Team projects requiring build reproducibility
- Long-term maintenance

### Team-Specific Local Recipes

Create organization-specific recipes for common patterns:

```
recipes/
  company-rust-backend.hbs    # Standard Rust backend config
  company-frontend.hbs         # Standard frontend build
  company-microservice.hbs     # Microservice template
```

```yaml
# icp.yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "file://recipes/company-rust-backend.hbs"
      configuration:
        package: backend
```

Benefits:
- Enforce company standards
- Share build optimizations
- Consistent tooling across teams
- Easier onboarding

Store team recipes in shared repository or package registry.

## Resource Budgeting

### Minimum Cycles for Production

Budget at least **1-2 trillion (T) cycles** minimum for production canisters:

```bash
# Initial deployment - budget 2T minimum
icp canister top-up --amount 2T backend
```

**Why 2T minimum:**
- Prevents freezing during traffic spikes
- Covers unexpected computation costs
- Provides buffer for delayed top-ups
- Freezing threshold reserve (30-90 days)

**Cycle consumption varies by:**
- Computation intensity
- Storage usage
- Query vs update call ratio
- Inter-canister calls

### Monitoring Canister Status

Regularly check canister cycles:

```bash
# Check cycles balance
icp canister status backend

# Output includes:
# Cycles: 1.8 T cycles
```

Set up monitoring alerts when cycles drop below threshold (e.g., 500B).

### Proactive Top-Up Strategies

**Manual top-up:**
```bash
icp canister top-up --amount 1T backend
```

**Automated top-up** (in application code):
- Monitor cycles in canister heartbeat
- Mint cycles from ICP when balance is low
- Alert operators when cycles drop below threshold

**Top-up schedule example:**
- Daily check for production canisters
- Top-up when balance < 1T
- Maintain 2-3T minimum reserve

### Freezing Threshold Configuration

Set freezing threshold to prevent unexpected freezing:

```yaml
canisters:
  backend:
    settings:
      freezing_threshold: 7776000  # 90 days (in seconds)
```

Default: 30 days (2592000 seconds)

**Recommended values:**
- **Development**: 7 days (604800 seconds) - allows faster iteration
- **Staging**: 30 days (2592000 seconds) - default is fine
- **Production**: 90 days (7776000 seconds) - maximum safety

Higher threshold = more cycles held in reserve = safer from freezing.

### Human-Readable Amount Formats

Use human-friendly formats for readability:

```bash
# Recommended: Human-readable
icp canister top-up --amount 2T backend        # 2 trillion
icp canister top-up --amount 500m backend      # 500 million
icp canister top-up --amount 1.5b backend      # 1.5 billion

# Also supported: Underscores
icp canister top-up --amount 2_000_000_000_000 backend

# Avoid: Raw numbers (hard to read)
icp canister top-up --amount 2000000000000 backend
```

Formats (NEW in beta.5):
- `k` or `K` = thousand
- `m` or `M` = million
- `b` or `B` = billion
- `T` = trillion
- Underscores: `1_000_000`

### Resource Allocation Guidelines

**Compute allocation:**
- 0 (default): No guarantee, pay-per-use
- 10-30: Moderate performance guarantee
- 50+: High performance, latency-sensitive

**Memory allocation:**
- Not set (default): Pay for actual usage
- Set explicit limit: For predictable billing, prevent runaway memory

Example production configuration:

```yaml
canisters:
  backend:
    settings:
      compute_allocation: 20         # 20% compute guarantee
      memory_allocation: 3GB         # 3 GB limit
      freezing_threshold: 7776000    # 90 days
      reserved_cycles_limit: 10T     # 10 trillion max reserve
```

## Security Patterns

### Identity Storage Backends

Choose storage backend based on environment:

**Production: Always Keyring**

```bash
icp identity new production --storage-mode keyring
```

Uses OS keychain (macOS Keychain, Windows Credential Manager, Linux Secret Service). Most secure option.

**Development: Keyring or Password-Protected**

```bash
# Keyring (recommended)
icp identity new dev --storage-mode keyring

# OR password-protected (for shared dev environments)
icp identity new dev --storage-mode password-protected
```

**CI/CD: Secrets Management + Password Files**

```bash
# Create password-protected identity
icp identity new ci --storage-mode password-protected

# Export for backup
icp identity export ci > ci.pem

# In CI/CD, use password file
echo "$CI_PASSWORD" > password.txt
ICP_IDENTITY_PASSWORD_FILE=password.txt icp deploy -e ic
```

Store `ci.pem` and password in secrets manager (GitHub Secrets, AWS Secrets Manager, etc.).

**Never Plaintext for Production**

```bash
# NEVER for production
icp identity new prod --storage-mode plaintext  # Insecure!
```

Plaintext stores private keys unencrypted. Only for throwaway local testing.

### Storage Mode Comparison

| Storage Mode | Security | Use Case |
|--------------|----------|----------|
| **keyring** | High (OS keychain) | Production, development |
| **password-protected** | Medium (encrypted with password) | CI/CD, shared environments |
| **plaintext** | Low (unencrypted) | Throwaway local testing only |

### Seed Phrase Backup

When creating identities, back up seed phrases offline:

```bash
icp identity new production --storage-mode keyring
# CLI displays seed phrase

# Write seed phrase on paper, store in secure location
# DO NOT store seed phrase digitally (screenshot, text file, etc.)
```

**Seed phrase security:**
- Write on paper
- Store in secure physical location (safe, safety deposit box)
- Never store digitally (no screenshots, text files, cloud storage)
- Consider using a hardware wallet for high-value identities

### Separate Identities Per Environment

Use different identities for each deployment environment:

```bash
# Development identity
icp identity new dev --storage-mode keyring
icp identity use dev

# Staging identity
icp identity new staging --storage-mode keyring

# Production identity
icp identity new production --storage-mode keyring
```

Benefits:
- Limit blast radius of compromised identity
- Clear audit trail per environment
- Different security policies (e.g., production requires hardware key)

### Controller Management for Critical Canisters

**Always have multiple controllers** for production canisters:

```yaml
canisters:
  backend:
    settings:
      controllers:
        - aaaaa-aa  # Primary operator
        - bbbbb-bb  # Backup operator
        - ccccc-cc  # Emergency access
```

**Safety Controls (Beta.5):**

CLI warns before removing yourself from controllers:

```bash
icp canister settings update backend --controllers aaaaa-aa

# Warning: You are about to remove yourself from the controllers.
# This will prevent you from managing this canister.
# Continue? [y/N]
```

**Use `--force` carefully** in scripts:

```bash
# Skips confirmation prompt (dangerous!)
icp canister settings update backend --controllers aaaaa-aa --force
```

**Best practices:**
- Always review controller changes
- Maintain at least 2 controllers for critical canisters
- Test controller changes on staging first
- Never accidentally lock yourself out

### Remote Recipe Integrity

Always include SHA-256 for remote recipes:

```yaml
# Secure: SHA-256 verification
canisters:
  backend:
    type: recipe
    recipe:
      type: "https://example.com/recipe.hbs"
      sha256: "abc123..."  # Required for integrity
      configuration:
        option: value
```

```yaml
# Insecure: No integrity check
canisters:
  backend:
    type: recipe
    recipe:
      type: "https://example.com/recipe.hbs"  # Missing sha256!
      configuration:
        option: value
```

SHA-256 prevents:
- Man-in-the-middle attacks
- Recipe tampering
- Accidental use of modified recipes

## Configuration Organization

### Modular Project Structures

Use external files for large projects:

```
my-project/
  icp.yaml              # Main config (imports others)
  canisters/
    backend.yaml        # Backend canister config
    frontend.yaml       # Frontend canister config
  environments/
    staging.yaml        # Staging environment
    production.yaml     # Production environment
  args/
    init.did            # Initialization arguments
```

```yaml
# icp.yaml (main config)
import:
  - canisters/backend.yaml
  - canisters/frontend.yaml
  - environments/staging.yaml
  - environments/production.yaml
```

Benefits:
- Clearer organization
- Easier to review changes (smaller files)
- Reusable components
- Team collaboration (less merge conflicts)

### Environment Separation

Separate configuration for local/staging/production:

```yaml
# icp.yaml
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust@v3.0.0"
      configuration:
        package: backend

environments:
  local:
    # Minimal resources for local dev
    canisters:
      backend:
        settings:
          compute_allocation: 0

  staging:
    network: ic
    canisters:
      backend:
        settings:
          compute_allocation: 20
          memory_allocation: 2GB

  production:
    network: ic
    canisters:
      backend:
        settings:
          compute_allocation: 50
          memory_allocation: 4GB
          freezing_threshold: 7776000
```

### Version Control

Add to `.gitignore`:

```
# .gitignore
.icp/*/canister_ids.json  # Ignore all canister IDs
.icp/*/wallets.json       # Ignore wallets
password.txt              # Never commit passwords
*.pem                     # Never commit private keys
```

**Except:** Commit canister IDs for deployed environments:

```
# .gitignore (revised)
.icp/local/              # Ignore local entirely
.icp/*/wallets.json      # Ignore wallets
password.txt             # Never commit passwords
*.pem                    # Never commit private keys

# Commit these
# .icp/staging/canister_ids.json
# .icp/production/canister_ids.json
```

Committing production canister IDs ensures:
- Team members reference same canisters
- Deployment scripts use correct IDs
- Disaster recovery (canister IDs preserved)

### Canister ID Versioning Strategy

Track canister IDs in version control:

```json
// .icp/production/canister_ids.json
{
  "backend": "rrkah-fqaaa-aaaaa-aaaaq-cai",
  "frontend": "ryjl3-tyaaa-aaaaa-aaaba-cai"
}
```

**When to commit:**
- After initial production deployment
- When creating new canisters
- When reassigning canister IDs

**When to .gitignore:**
- Local development IDs (change frequently)
- Temporary test canister IDs

### Secret Management

**Never commit secrets** to version control:

```yaml
# BAD: Hardcoded secrets
canisters:
  backend:
    settings:
      environment_variables:
        - name: API_KEY
          value: "secret-key-123"  # Don't do this!
```

**Good: Reference environment variables:**

```yaml
# GOOD: Reference env vars
canisters:
  backend:
    settings:
      environment_variables:
        - name: API_KEY
          value: "${API_KEY}"  # Filled from environment
```

```bash
# Set in environment
export API_KEY="secret-key-123"
icp deploy -e production
```

**Better: Use secrets management:**

- AWS Secrets Manager
- HashiCorp Vault
- GitHub Secrets (for CI/CD)
- 1Password / Bitwarden (for local dev)

## Platform-Specific Guidance

### Windows (NEW in Beta.5)

**Full Windows Support Added:**

Beta.5 adds native Windows support with platform-specific requirements.

**Rust Canisters:**
- Fully supported natively on Windows
- No WSL required
- Install icp-cli on Windows directly

**Motoko Canisters:**
- Require WSL (Windows Subsystem for Linux)
- Motoko compiler doesn't run natively on Windows
- Install icp-cli inside WSL for Motoko development

**Local Networks:**
- Require Docker Desktop (mandatory)
- Both managed and containerized networks need Docker
- Ensure Docker Desktop is running before `icp network start`

**Setup for Windows:**

```bash
# For Rust canisters (native Windows)
# Install icp-cli on Windows
winget install icp-cli

# Start Docker Desktop
# Run commands in PowerShell/CMD
icp network start -d
icp deploy

# For Motoko canisters (requires WSL)
# Install Ubuntu from Microsoft Store
# Install icp-cli inside WSL
wsl
curl -sSL https://get.icp.sh | sh
icp network start -d  # Requires Docker Desktop on Windows host
icp deploy
```

### macOS and Linux

**Full Native Support:**

All canister types (Rust, Motoko, Assets) fully supported natively.

**Docker:**
- Required only for containerized networks
- Optional for managed networks (runs PocketIC natively)

**Recommended Setup:**

```bash
# Install icp-cli
curl -sSL https://get.icp.sh | sh

# No Docker needed for managed networks
icp network start -d
icp deploy

# Docker needed for containerized networks
docker pull ghcr.io/dfinity/pocketic:latest
# Configure containerized network in icp.yaml
icp network start -d
```

### Large WASM Modules (Beta.5)

**Automatic Chunked Uploads:**

WASM modules larger than 2MB are automatically uploaded in chunks.

**No manual action required:**

```bash
# Works automatically for large WASM
icp canister install backend
# CLI detects large WASM and chunks upload automatically
```

**Benefits:**
- No more manual chunking
- Works transparently
- Handles multi-megabyte WASM files

**Optimization still recommended:**

```bash
# Use ic-wasm to optimize before deployment
ic-wasm target/wasm32-unknown-unknown/release/backend.wasm -o backend_optimized.wasm optimize O3
```

Even though chunking is automatic, smaller WASM = lower deployment cycles cost.

## Migration from dfx

### Command Mapping

| dfx Command | icp Command |
|-------------|-------------|
| `dfx new` | `icp new` |
| `dfx build` | `icp build` |
| `dfx deploy` | `icp deploy` |
| `dfx canister create` | `icp canister create` |
| `dfx canister install` | `icp canister install` |
| `dfx canister call` | `icp canister call` |
| `dfx canister status` | `icp canister status` |
| `dfx identity new` | `icp identity new` |
| `dfx identity use` | `icp identity use` |
| `dfx ledger account-id` | `icp identity account-id` |
| `dfx cycles balance` | `icp cycles balance` |
| `dfx wallet send` | `icp cycles transfer` |

### Configuration Migration

**dfx.json (old) → icp.yaml (new):**

```json
// dfx.json (old)
{
  "canisters": {
    "backend": {
      "type": "rust",
      "package": "backend",
      "candid": "backend.did"
    }
  },
  "networks": {
    "local": {
      "bind": "127.0.0.1:8000"
    }
  }
}
```

```yaml
# icp.yaml (new)
canisters:
  backend:
    type: recipe
    recipe:
      type: "@dfinity/rust"
      configuration:
        package: backend

networks:
  local:
    type: managed
```

### Network Naming (BREAKING in Beta.5)

**"mainnet" renamed to "ic":**

```bash
# Old (dfx)
dfx deploy --network mainnet

# Old (icp-cli beta.4 and earlier)
icp deploy --mainnet

# New (icp-cli beta.5+)
icp deploy -e ic
```

**Flags removed:**
- `--mainnet` removed (use `-e ic`)
- `--ic` removed (use `-e ic`)

**Use `-e ic` or `-n ic`** for mainnet deployments.

### Cycles Command Changes (Beta.5)

**Cycles transfer command changed:**

```bash
# Old (beta.4 and earlier)
icp token cycles transfer --to <canister-id> --amount 2T

# New (beta.5+)
icp cycles transfer --to <canister-id> --amount 2T
```

`icp token cycles transfer` removed. Use `icp cycles transfer`.

### Canister ID Preservation

Canister IDs are preserved during migration:

```bash
# Copy canister IDs from dfx
cp .dfx/local/canister_ids.json .icp/local/canister_ids.json
cp .dfx/ic/canister_ids.json .icp/ic/canister_ids.json

# icp-cli uses existing IDs
icp deploy
```

### Testing Migration Locally First

Always test migration on local network before IC:

```bash
# 1. Test locally
icp network start -d
icp deploy
icp canister call backend method '()'

# 2. Verify everything works
icp canister status backend

# 3. Then migrate IC deployment
icp deploy -e ic
```

## Summary

Follow these best practices:

1. **Recipes**: Use official recipes with version pinning for production
2. **Cycles**: Budget 1-2T minimum, monitor regularly, use human-readable amounts
3. **Security**: Keyring storage, multiple controllers, separate identities per environment
4. **Configuration**: Modular structure, environment separation, .gitignore secrets
5. **Platform**: Use WSL for Motoko on Windows, Docker Desktop for local networks
6. **Migration**: Test locally first, use `-e ic` (not --mainnet), update cycles commands
