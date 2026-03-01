# GitHub Actions Terraform Pipeline - Setup Guide

## Overview

This GitHub Actions pipeline automates infrastructure deployment to Azure using Terraform with three main steps:

1. **Plan & Cost Analysis**: Generates Terraform plan and calculates infrastructure costs using Infracost
2. **Approval Gate**: Requires manual approval from authorized users before deployment
3. **Apply**: Deploys infrastructure to Azure based on the approved plan

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  GitHub Push/PR Event                                       │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────▼──────────────┐
        │  STEP 1: Plan & Costs     │
        │  ├─ Terraform Init        │
        │  ├─ Terraform Validate    │
        │  ├─ Terraform Plan        │
        │  └─ Infracost Analysis    │
        └────────────┬──────────────┘
                     │
        ┌────────────▼──────────────┐
        │  STEP 2: Approval Gate    │
        │  (gate-env)               │
        │  ⏳ Awaiting Approval     │
        └────────────┬──────────────┘
                     │
        ┌────────────▼──────────────┐
        │  STEP 3: Apply            │
        │  ├─ Download Plan         │
        │  ├─ Terraform Apply       │
        │  └─ Report Results        │
        └────────────┬──────────────┘
                     │
        ┌────────────▼──────────────┐
        │  ✅ Infrastructure Ready  │
        └──────────────────────────┘
```

## Prerequisites

### 1. Azure Resources

You need an **Azure Enterprise Application** with federated credentials for GitHub OIDC authentication:

```
Azure AD
├── Enterprise Application (Service Principal)
├── Federated Credentials (GitHub OIDC)
└── Role Assignment (Contributor or custom)
```

**Roles Required**:
- **Contributor** on subscription (minimum recommended)
- Or custom role for specific resource groups

### 2. GitHub Repository Secrets

Add these secrets to your GitHub repository (Settings → Secrets):

| Secret | Required | Description |
|--------|----------|-------------|
| `AZURE_CLIENT_ID` | ✅ | Azure Enterprise Application (Client) ID |
| `AZURE_TENANT_ID` | ✅ | Azure AD Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | ✅ | Azure Subscription ID |
| `INFRACOST_API_KEY` | ❌ | Infracost API key (optional, for cost analysis) |
| `GITHUB_TOKEN` | ✅ (Auto) | Automatically provided by GitHub |

### 3. GitHub Environment Protection

Create a protected environment `gate-env` for the approval gate:

```
Repository Settings → Environments → Create environment "gate-env"
```

Configure protection rules:
- **Required Reviewers**: Add users/teams who can approve deployments
- **Prevent self-review**: ✅ (recommended)
- **Deployment branches**: Main branch only

## Setup Instructions

### Step 1: Create Azure Enterprise Application & Federated Credentials

#### Via Azure Portal:

1. **Create Service Principal**:
   ```
   Azure AD → App registrations → New registration
   Name: github-terraform-deployer
   ```

2. **Create Federated Credential**:
   ```
   App → Certificates & secrets → Federated credentials → New
   
   Scenario: GitHub Actions deploying to Azure
   Organization: <your-github-org>
   Repository: <your-repo-name>
   Entity Type: Environment
   Environment Name: gate-env
   Name: github-terraform-federated
   ```

3. **Note the values**:
   - Application (client) ID → `AZURE_CLIENT_ID`
   - Tenant ID → `AZURE_TENANT_ID`
   - Subscription ID → `AZURE_SUBSCRIPTION_ID`

#### Via Azure CLI (Recommended):

```bash
# Set variables
GITHUB_ORG="your-github-org"
GITHUB_REPO="ad-demo-terraform-projects"
APP_NAME="github-terraform-deployer"

# Create Service Principal
az ad app create --display-name $APP_NAME
APP_ID=$(az ad app list --display-name $APP_NAME --query '[0].id' -o tsv)
CLIENT_ID=$(az ad app list --display-name $APP_NAME --query '[0].appId' -o tsv)

# Create federated credentials
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-terraform",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':environment:gate-env",
    "description": "GitHub Actions Terraform"
  }'

# Create Service Principal
az ad sp create --id $CLIENT_ID

# Get Tenant ID
TENANT_ID=$(az account show --query 'tenantId' -o tsv)

# Assign Contributor role
SUBSCRIPTION_ID=$(az account show --query 'id' -o tsv)
az role assignment create \
  --assignee $CLIENT_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID

# Output credentials
echo "Add these as GitHub secrets:"
echo "AZURE_CLIENT_ID=$CLIENT_ID"
echo "AZURE_TENANT_ID=$TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
```

### Step 2: Add GitHub Secrets

1. Go to **Repository Settings → Secrets → Actions**
2. Add the values from Step 1:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

3. (Optional) Add Infracost API key:
   - Visit https://dashboard.infracost.io/account/api-key
   - Add as `INFRACOST_API_KEY` secret

### Step 3: Create Protected Environment

1. **Settings → Environments → New environment**
   - Name: `gate-env`

2. **Configure Protection Rules**:
   - ✅ Enable "Required reviewers"
   - Add team or users who can approve
   - ✅ Enable "Prevent self-review"
   - Set "Deployment branches" to "main"

3. **Save**

### Step 4: Commit Workflow

The workflow file is already at:
```
.github/workflows/terraform-deploy.yml
```

Commit and push to main:

```bash
git add .github/workflows/terraform-deploy.yml
git commit -m "ci: add terraform deployment pipeline"
git push origin main
```

## Workflow Triggers

### Pull Request Trigger
- **Event**: PR to main branch
- **Steps**: 1 (Plan & Costs only)
- **Approval**: Not required
- **Apply**: Not executed

**Use Case**: Review changes before merging

### Main Branch Push Trigger
- **Event**: Push to main branch
- **Steps**: 1 → 2 → 3
- **Approval**: Required (Step 2)
- **Apply**: After approval (Step 3)

**Use Case**: Automatic deployment after code review

## Manual Approval Process

When changes are pushed to main:

1. **Step 1 completes automatically** ✅
   - Terraform plan generated
   - Costs calculated
   - PR comment with details added

2. **Step 2 waits for approval** ⏳
   - Go to: **Actions → Latest Run → Review pending deployments**
   - Or: **Environments → gate-env → Active deployments**
   - Click **Review deployments**
   - Click **Approve and deploy**
   - Authorized reviewers only

3. **Step 3 executes automatically** ✅
   - Terraform apply runs
   - Infrastructure deployed
   - Results published

## Environment Variables

The workflow sets these automatically:

```bash
ARM_USE_OIDC=true                    # Use OpenID Connect
ARM_CLIENT_ID=...                    # From secrets
ARM_TENANT_ID=...                    # From secrets
ARM_SUBSCRIPTION_ID=...              # From secrets
ARM_OIDC_TOKEN=...                   # GitHub Actions token
TERRAFORM_VERSION=1.7.0              # Can be customized
INFRACOST_API_KEY=...               # Optional
```

## Viewing Results

### In GitHub Actions UI

1. **Go to Workflow Run**:
   - Repository → Actions → Terraform Plan & Deploy

2. **Step Details**:
   - Click job name to expand logs
   - Check specific steps for details

3. **Artifacts**:
   - Download plan and apply logs
   - Retention: 7 days for plan, 30 days for apply logs

### In PR Comments

When PR is created:
- Terraform plan shown in PR comment
- Infrastructure costs displayed
- Easy review before merge

### Deployment Report

After successful apply:
- Check run created with outputs
- Deployed resources listed
- Timestamps and actor information

## Troubleshooting

### Issue: "Azure Login Failed"

**Cause**: Federated credentials not configured or invalid

**Solution**:
```bash
# Verify federated credential
az ad app federated-credential list --id <app-id>

# Check role assignment
az role assignment list --assignee <client-id>
```

### Issue: "Plan Artifacts Not Found"

**Cause**: Plan generation failed

**Solution**:
- Check terraform validate step logs
- Verify ENVVARS/project1.json is valid
- Confirm backend configuration is correct

### Issue: "Approval Not Showing Up"

**Cause**: Environment protection not configured

**Solution**:
```
Settings → Environments → gate-env → protection rules enabled
```

### Issue: "Infracost API Error"

**Cause**: API key not set or invalid

**Solution**:
- Optional feature - workflow continues without it
- Get key from: https://dashboard.infracost.io/account/api-key
- Or skip by not setting `INFRACOST_API_KEY` secret

## Security Best Practices

✅ **Enabled in this Workflow**:

1. **Federated Identity**: No secrets stored, uses OIDC tokens
2. **Principle of Least Privilege**: Only required permissions
3. **Approval Gate**: Manual review before production changes
4. **Lock State**: Terraform state locked during apply
5. **Audit Trail**: Full GitHub Actions logs
6. **Artifact Retention**: Limited retention period

⚠️ **Recommended Additional Steps**:

1. **Restrict branch protection**:
   ```
   main branch → Require pull request reviews
   main branch → Dismiss stale pull request approvals
   ```

2. **Enable branch protection**:
   ```
   Settings → Branches → Protected branches
   Add rule for "main":
   - Require approval before merging
   - Require status checks to pass
   - Require branches up to date
   ```

3. **Enable audit logging**:
   ```
   Settings → Audit log → Review deployment approvals
   ```

4. **Rotate credentials periodically**:
   - Update federated credentials annually
   - Review service principal permissions

## Cost Tracking

The pipeline tracks infrastructure costs via Infracost:

- **Displayed in**: PR comments, workflow logs
- **Format**: JSON report
- **Coverage**: Most Azure resources
- **Update**: Recalculated on every plan

To customize Infracost:

```yaml
# In workflow, modify infracost command:
infracost breakdown \
  --path=/tmp/tf-artifacts/tfplan.json \
  --format=json \
  --compare-to=master  # Compare to baseline
```

## Advanced: Custom Resource Groups

To deploy to specific resource groups:

1. **Modify federated credential scope**:
   ```bash
   # Instead of subscription-wide
   /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}
   ```

2. **Adjust role scope** in Azure:
   ```bash
   az role assignment create \
     --assignee $CLIENT_ID \
     --role "Terraform Operator" \
     --scope "/subscriptions/$SUB_ID/resourceGroups/$RG_NAME"
   ```

3. **Update terraform backend** (if needed):
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "tfstate-rg"
       storage_account_name = "tfstatesa"
       container_name       = "tfstate"
       key                  = "proj1.terraform.tfstate"
     }
   }
   ```

## Next Steps

1. ✅ Create Azure Enterprise Application and federated credentials
2. ✅ Add GitHub repository secrets
3. ✅ Create protected environment `gate-env`
4. ✅ Push workflow to repository
5. ✅ Create a test PR to verify Step 1
6. ✅ Push to main and approve to test Steps 2-3
7. ✅ Monitor deployments and costs

## References

- [GitHub OIDC in Azure](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [Federated Credentials](https://aka.ms/azureoidc)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Infracost](https://www.infracost.io/)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)

---

**Need Help?**

- Review workflow logs: Actions → Run → Job → Logs
- Check Azure portal: Subscription → Activity log
- Verify secrets: Settings → Secrets → Actions
