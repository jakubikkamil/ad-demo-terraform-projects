# Azure Federated Identity - Quick Setup Script

This script automates the setup of Azure Enterprise Application and Federated Credentials for GitHub Actions.

## Prerequisites

- Azure CLI installed (`az --version`)
- Owner or Admin access to Azure subscription
- Owner/Admin access to GitHub repository

## Quick Setup (5 minutes)

```bash
#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION - CUSTOMIZE THESE
# ═══════════════════════════════════════════════════════════════════════════

GITHUB_ORG="your-github-org"           # e.g., "kamil-dev" or "my-company"
GITHUB_REPO="ad-demo-terraform-projects"  # Repository name
APP_NAME="github-terraform-deployer"      # Service Principal name
ENVIRONMENT_NAME="gate-env"               # GitHub Actions environment

# ═══════════════════════════════════════════════════════════════════════════
# DO NOT EDIT BELOW THIS LINE
# ═══════════════════════════════════════════════════════════════════════════

echo "🚀 Setting up Azure Federated Identity for GitHub Actions"
echo ""
echo "Configuration:"
echo "  Organization: $GITHUB_ORG"
echo "  Repository: $GITHUB_REPO"
echo "  Environment: $ENVIRONMENT_NAME"
echo "  App Name: $APP_NAME"
echo ""

# Step 1: Get current Azure context
echo "📍 Step 1: Getting Azure subscription info..."
SUBSCRIPTION_ID=$(az account show --query 'id' -o tsv)
TENANT_ID=$(az account show --query 'tenantId' -o tsv)
SUBSCRIPTION_NAME=$(az account show --query 'name' -o tsv)

echo "✓ Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo "✓ Tenant ID: $TENANT_ID"
echo ""

# Step 2: Create or update Enterprise Application
echo "🔷 Step 2: Creating Enterprise Application..."

# Check if app already exists
EXISTING_APP=$(az ad app list --display-name "$APP_NAME" --query '[0]' 2>/dev/null || echo "")

if [ ! -z "$EXISTING_APP" ]; then
  echo "⚠️  App '$APP_NAME' already exists, using existing..."
  APP_ID=$(echo "$EXISTING_APP" | jq -r '.id')
  CLIENT_ID=$(echo "$EXISTING_APP" | jq -r '.appId')
else
  # Create new app registration
  echo "Creating new app registration: $APP_NAME"
  APP_RESPONSE=$(az ad app create --display-name "$APP_NAME")
  APP_ID=$(echo "$APP_RESPONSE" | jq -r '.id')
  CLIENT_ID=$(echo "$APP_RESPONSE" | jq -r '.appId')
  echo "✓ App created"
fi

echo "✓ Application ID: $APP_ID"
echo "✓ Client ID: $CLIENT_ID"
echo ""

# Step 3: Create or update Federated Credential
echo "🔐 Step 3: Creating Federated Credential..."

CRED_NAME="github-$GITHUB_ORG-$GITHUB_REPO"
CRED_SUBJECT="repo:$GITHUB_ORG/$GITHUB_REPO:environment:$ENVIRONMENT_NAME"

# Check if credential already exists
EXISTING_CRED=$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$CRED_NAME']" 2>/dev/null || echo "[]")

if [ "$(echo "$EXISTING_CRED" | jq 'length')" -gt 0 ]; then
  echo "⚠️  Credential '$CRED_NAME' already exists"
  echo "Skipping creation (use 'az ad app federated-credential delete' to remove first)"
else
  # Create federated credential
  az ad app federated-credential create \
    --id "$APP_ID" \
    --parameters "{
      \"name\": \"$CRED_NAME\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"$CRED_SUBJECT\",
      \"audiences\": [\"api://AzureADTokenExchange\"],
      \"description\": \"GitHub Actions for $GITHUB_REPO\"
    }"
  echo "✓ Federated credential created"
  echo "  Subject: $CRED_SUBJECT"
fi
echo ""

# Step 4: Create Service Principal if needed
echo "👤 Step 4: Creating Service Principal..."

# Check if service principal already exists
SP_CHECK=$(az ad sp list --display-name "$APP_NAME" --query '[0]' 2>/dev/null || echo "")

if [ -z "$SP_CHECK" ]; then
  az ad sp create --id "$CLIENT_ID"
  echo "✓ Service Principal created"
else
  echo "✓ Service Principal already exists"
fi
echo ""

# Step 5: Assign roles
echo "🔑 Step 5: Assigning roles..."

# Check if Contributor role already assigned
ROLE_ASSIGNMENT=$(az role assignment list \
  --assignee "$CLIENT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --query '[0]' 2>/dev/null || echo "")

if [ -z "$ROLE_ASSIGNMENT" ]; then
  az role assignment create \
    --assignee "$CLIENT_ID" \
    --role "Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID"
  echo "✓ Contributor role assigned to subscription"
else
  echo "✓ Contributor role already assigned"
fi
echo ""

# Step 6: Display GitHub Secrets
echo "═══════════════════════════════════════════════════════════════════════"
echo "✅ Setup Complete!"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "📋 Add these as GitHub Secrets:"
echo ""
echo "Repository: $GITHUB_ORG/$GITHUB_REPO"
echo "Settings → Secrets → Actions → New repository secret"
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│ Secret Name: AZURE_CLIENT_ID                                │"
echo "│ Value:       $CLIENT_ID"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│ Secret Name: AZURE_TENANT_ID                                │"
echo "│ Value:       $TENANT_ID"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│ Secret Name: AZURE_SUBSCRIPTION_ID                          │"
echo "│ Value:       $SUBSCRIPTION_ID"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "🔐 Create GitHub Environment (if not exists):"
echo ""
echo "1. Go to: Settings → Environments → New environment"
echo "2. Name: $ENVIRONMENT_NAME"
echo "3. Add protection rule:"
echo "   - Required reviewers: [Select teams/users for approval]"
echo "   - Prevent self-review: ✓"
echo "   - Deployment branches: main"
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "✨ Next Steps:"
echo ""
echo "1. Copy the secrets above to GitHub"
echo "2. Create the GitHub environment 'gate-env' with protection rules"
echo "3. Push .github/workflows/terraform-deploy.yml to repository"
echo "4. Test by pushing to main branch"
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
```

## Step-by-Step Usage

### 1. Save the Script

```bash
# Save as setup-azure-federated.sh
cat > setup-azure-federated.sh << 'EOF'
[paste script above]
EOF

chmod +x setup-azure-federated.sh
```

### 2. Customize Configuration

Edit the script with your details:

```bash
GITHUB_ORG="your-org"                    # Your GitHub org/user
GITHUB_REPO="ad-demo-terraform-projects" # Repository name
```

### 3. Run the Script

```bash
./setup-azure-federated.sh
```

### 4. Copy Output to GitHub

The script will display the secrets needed. Copy them:

```bash
# GitHub Settings → Secrets → Actions → New repository secret
```

### 5. Create Protected Environment

```
Settings → Environments → New environment
Name: gate-env
Add required reviewers
```

## Manual Step-by-Step (No Script)

If you prefer to do this manually:

```bash
# 1. Set variables
GITHUB_ORG="your-org"
GITHUB_REPO="ad-demo-terraform-projects"
APP_NAME="github-terraform-deployer"
ENVIRONMENT_NAME="gate-env"

# 2. Get subscription info
SUBSCRIPTION_ID=$(az account show --query 'id' -o tsv)
TENANT_ID=$(az account show --query 'tenantId' -o tsv)

# 3. Create app registration
az ad app create --display-name $APP_NAME
CLIENT_ID=$(az ad app list --display-name $APP_NAME --query '[0].appId' -o tsv)
APP_ID=$(az ad app list --display-name $APP_NAME --query '[0].id' -o tsv)

# 4. Create federated credential
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{
    \"name\": \"github-$GITHUB_ORG-$GITHUB_REPO\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$GITHUB_ORG/$GITHUB_REPO:environment:$ENVIRONMENT_NAME\",
    \"audiences\": [\"api://AzureADTokenExchange\"],
    \"description\": \"GitHub Actions\"
  }"

# 5. Create service principal
az ad sp create --id $CLIENT_ID

# 6. Assign Contributor role
az role assignment create \
  --assignee $CLIENT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# 7. Display secrets
echo "AZURE_CLIENT_ID=$CLIENT_ID"
echo "AZURE_TENANT_ID=$TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
```

## Verification Commands

### Verify Federated Credential

```bash
# List all credentials for the app
az ad app federated-credential list --id <app-id>

# Should show:
# - name: github-org-repo
# - subject: repo:org/repo:environment:gate-env
# - issuer: https://token.actions.githubusercontent.com
```

### Verify Role Assignment

```bash
# Check what roles are assigned
az role assignment list --assignee <client-id>

# Should include: Contributor on subscription
```

### Verify Service Principal

```bash
# List service principals
az ad sp list --filter "appId eq '<client-id>'"
```

## Cleanup (If Needed)

### Delete Everything

```bash
# Remove federated credential
az ad app federated-credential delete --id <app-id> --name <cred-name>

# Remove role assignment
az role assignment delete --assignee <client-id> --role Contributor

# Delete service principal
az ad sp delete --id <client-id>

# Delete app registration
az ad app delete --id <app-id>
```

## Troubleshooting

### Error: "Insufficient privileges to complete the operation"

**Cause**: Not enough permissions in Azure

**Solution**:
- Get Azure subscription owner to run the setup
- Or assign yourself "Application administrator" role

### Error: "The app already exists"

**Cause**: App with same name already exists

**Solution**:
- Use different `APP_NAME` or
- Delete existing app first: `az ad app delete --id <app-id>`

### Error: "Invalid federated credential subject"

**Cause**: Wrong repo name or org name

**Solution**:
- Verify `GITHUB_ORG` and `GITHUB_REPO` match your GitHub settings
- Check GitHub "Environments" page for exact environment name

### GitHub Actions Fails: "Authentication failed"

**Cause**: Secrets not set or incorrect values

**Solution**:
```bash
# Verify secrets are set
# Go to Settings → Secrets → Actions

# Verify values are correct
AZURE_CLIENT_ID=$(az ad app list --display-name "github-terraform-deployer" --query '[0].appId' -o tsv)
echo "Should match: $AZURE_CLIENT_ID"
```

## Advanced: Custom Role (Least Privilege)

For better security, use a custom role instead of Contributor:

```bash
# Create custom role
az role definition create --role-definition '{
  "Name": "Terraform Deployer",
  "Description": "Permissions for Terraform to deploy resources",
  "Type": "CustomRole",
  "Permissions": [
    {
      "Actions": [
        "Microsoft.Storage/*/read",
        "Microsoft.Storage/storageAccounts/*",
        "Microsoft.KeyVault/*/read",
        "Microsoft.KeyVault/vaults/*",
        "Microsoft.Resources/deployments/*",
        "Microsoft.Resources/subscriptions/resourceGroups/*"
      ],
      "NotActions": []
    }
  ],
  "AssignableScopes": [
    "/subscriptions/'$SUBSCRIPTION_ID'"
  ]
}'

# Assign custom role
az role assignment create \
  --assignee $CLIENT_ID \
  --role "Terraform Deployer" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

## References

- [Azure OIDC with GitHub](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [Federated Credentials](https://learn.microsoft.com/en-us/graph/api/application-post-federatedidentitycredentials)
- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/)
