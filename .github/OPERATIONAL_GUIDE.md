# GitHub Actions Terraform Pipeline - Operational Guide

This guide explains how the pipeline works in practice and how to use it.

## Pipeline Flow Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          PULL REQUEST WORKFLOW                           │
└──────────────────────────────────────────────────────────────────────────┘

Git Commit → Push PR to main
    ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔷 STEP 1: Terraform Plan & Cost Analysis (automatic)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Checkout code
  ✓ Setup Terraform + Infracost
  ✓ Authenticate to Azure
  ✓ terraform init
  ✓ terraform validate
  ✓ terraform plan
  ✓ infracost estimate
  ✓ Post PR comment with plan & costs
    ↓
📝 PR Comment Added
  - Shows resource changes
  - Shows estimated costs
  - Ready for code review
    ↓
👥 Code Review & Merge
  - Team reviews plan
  - Approves PR
  - Merges to main
    ↓

┌──────────────────────────────────────────────────────────────────────────┐
│                        MAIN BRANCH WORKFLOW                              │
└──────────────────────────────────────────────────────────────────────────┘

Git Commit → Push to main
    ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔷 STEP 1: Terraform Plan & Cost Analysis (automatic)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Same as PR workflow
    ↓
🔐 STEP 2: Approval Gate (manual - blocked)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⏳ WAITING FOR APPROVAL
  
  Notification:
  - GitHub sends email to reviewers
  - Actions tab shows "Review pending deployments"
  - Deployment cannot proceed without approval
    ↓
    [⏳ Only authorized reviewers can approve]
    ↓
👤 Reviewer Approval
  1. Open GitHub Actions → Workflow Run
  2. Click "Review pending deployments"
  3. Check the plan details
  4. Click "Approve and deploy"
    ↓
🚀 STEP 3: Terraform Apply (automatic after approval)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Download plan from Step 1
  ✓ terraform apply
  ✓ Collect outputs
  ✓ Post deployment summary
    ↓
✅ Deployment Complete
  - Infrastructure deployed to Azure
  - Outputs published
  - Audit log recorded
```

## Using the Pipeline

### Scenario 1: Proposing Changes (PR)

**Goal**: Review infrastructure changes before deploying

**Steps**:

1. **Create feature branch**:
   ```bash
   git checkout -b feature/add-keyvault
   ```

2. **Make Terraform changes**:
   ```bash
   # Edit project1 terraform files
   vim projects/project1/terraform/main.tf
   vim projects/project1/ENVVARS/project1.json
   ```

3. **Commit and push**:
   ```bash
   git add projects/project1/
   git commit -m "feat: add key vault resource"
   git push origin feature/add-keyvault
   ```

4. **Create Pull Request**:
   - GitHub → Create PR to main
   - Title: "Add key vault resource"
   - Description: Explain changes

5. **GitHub Actions Runs**:
   - ✅ Automatically runs Step 1 only
   - No approval needed
   - No infrastructure changed

6. **Review Results**:
   - Check PR comment for plan
   - Review costs
   - Request changes if needed
   - Approve and merge

7. **Result**:
   - Plan ready in PR
   - Next: Push to main for deployment

### Scenario 2: Deploying Changes (Main Branch Push)

**Goal**: Deploy infrastructure changes to production

**Steps**:

1. **Merge PR to main**:
   - Code reviewed
   - PR comment verified
   - Click "Merge pull request"

2. **GitHub Actions Runs**:
   - ✅ Step 1: Plan & Costs (automatic)
   - ⏳ Step 2: Approval Gate (waiting)
   - ⏸️ Step 3: Apply (blocked until approved)

3. **Receive Notification**:
   - GitHub email to reviewers
   - Subject: "Deployment of ad-demo-terraform-projects awaits your review"
   - Link to approve

4. **Review & Approve**:
   ```
   GitHub → Actions → [Latest run]
   → Review pending deployments
   → Check plan and costs
   → "Approve and deploy"
   ```

5. **GitHub Actions Completes**:
   - ✅ Step 2: Approval confirmed
   - ✅ Step 3: Terraform apply starts
   - Resources deployed to Azure
   - Outputs published
   - Summary posted

6. **Verify Deployment**:
   ```bash
   # Check Azure portal for new resources
   az resource list --resource-group "proj1-rg" --query "[].name" -o table
   
   # Or check workflow outputs
   GitHub → Actions → [Run] → [Apply job] → Outputs
   ```

### Scenario 3: Emergency Rollback

**Goal**: Quickly revert infrastructure changes

**Steps**:

1. **Identify Issue**:
   - Check deployment summary
   - Review error logs
   - Confirm what needs to be reverted

2. **Revert Code**:
   ```bash
   # Option A: Revert commit
   git revert HEAD
   git push origin main
   
   # Option B: Fix and recommit
   git checkout -b fix/revert-keyvault
   git revert HEAD
   git push origin fix/revert-keyvault
   # Create PR, review, merge
   ```

3. **Approve New Plan**:
   - Step 1 generates reverse plan (destroys resources)
   - Review and approve deployment
   - Resources removed

4. **Result**:
   - Infrastructure reverted
   - Audit trail preserved

## Approval Process Details

### Understanding the Approval Gate

The **gate-env** environment is protected and requires approval:

```
Settings → Environments → gate-env
├── Required reviewers: [Your team]
├── Prevent self-review: ✓
└── Deployment branches: main
```

### Who Can Approve?

Only users added as "Required reviewers":

```
Settings → Environments → gate-env → Edit protection rules
→ Required reviewers → Add users or teams
```

### How to Approve

**Method 1: From GitHub Email**

```
Email from GitHub Actions:
Subject: Deployment of repo awaits your review

Click: "Review deployment" link
```

**Method 2: From GitHub Web UI**

```
Repository → Actions
→ Select workflow run
→ "Review pending deployments" button
→ View summary
→ "Approve and deploy" button
```

**Method 3: From GitHub CLI**

```bash
# List pending deployments
gh run view <run-id> --json=conclusions

# Approve deployment (if you have permissions)
gh deployment approve-or-reject-deployment <deployment-id> --approve
```

### Approval Timeout

- Deployments waiting for approval do **NOT** timeout
- They wait indefinitely

### Cancelling Approval

To cancel a pending deployment:

```
GitHub → Actions → [Run] → [Job] → Cancel workflow
```

## Artifacts & Outputs

### What Gets Saved?

The pipeline saves these artifacts:

| Artifact | Retention | Location | Contents |
|----------|-----------|----------|----------|
| `terraform-plan-artifacts` | 7 days | Actions → Artifacts | Binary plan, JSON plan, text plan, infracost JSON |
| `terraform-apply-logs` | 30 days | Actions → Artifacts | terraform apply output |

### Accessing Artifacts

**Option 1: Via Web UI**

```
Repository → Actions
→ Select workflow run
→ Artifacts section
→ Download ZIP
```

**Option 2: Via GitHub CLI**

```bash
# List artifacts
gh run download <run-id> --dir artifacts/

# Download specific artifact
gh run download <run-id> --name terraform-plan-artifacts --dir plan/
```

### Understanding Artifacts

**tfplan.binary**
- Binary Terraform plan
- Used for `terraform apply`
- Only needed if manually applying

**tfplan.json**
- JSON representation of plan
- Used by infracost
- For cost analysis

**infracost.json**
- Detailed cost breakdown
- By resource type
- Monthly costs

**outputs.json** (after apply)
- Infrastructure outputs
- DNS names, IDs, endpoints
- Connection strings

## Monitoring & Troubleshooting

### Monitor Active Deployments

```
Repository → Deployments
→ Shows active/completed deployments
→ Click deployment to see workflow run
```

### Check Workflow Status

```
Repository → Actions
→ Select workflow run
→ View job details
→ Review logs
```

### Common Issues

#### Issue: "Approval Not Appearing"

**Symptoms**: Step 2 shows no approval option

**Causes**:
- Environment `gate-env` not created
- Not logged in as authorized reviewer
- Branch protection rules blocking

**Fix**:
1. Create environment: Settings → Environments → New → gate-env
2. Add required reviewers
3. Verify user is in reviewer group
4. Re-run workflow

#### Issue: "Plan Artifacts Missing"

**Symptoms**: Step 3 fails with "plan not found"

**Causes**:
- Artifact retention expired (7 days)
- terraform plan failed in Step 1
- Network issues during upload

**Fix**:
1. Check Step 1 logs for errors
2. Increase artifact retention (in workflow YAML)
3. Retry deployment

#### Issue: "Azure Authentication Failed"

**Symptoms**: Step 1 fails during "Azure Login"

**Causes**:
- Secrets not set correctly
- Federated credential misconfigured
- Service principal lacks permissions

**Fix**:
1. Verify secrets: Settings → Secrets → Actions
2. Verify federated credential:
   ```bash
   az ad app federated-credential list --id <app-id>
   ```
3. Verify role assignment:
   ```bash
   az role assignment list --assignee <client-id>
   ```

#### Issue: "Infracost API Error"

**Symptoms**: Step 1 completes but costs show "N/A"

**Causes**:
- `INFRACOST_API_KEY` not set (optional)
- API key expired or invalid
- Rate limit exceeded

**Fix**:
1. Get API key: https://dashboard.infracost.io/account/api-key
2. Add as GitHub secret: `INFRACOST_API_KEY`
3. Re-run workflow

#### Issue: "Terraform Validation Failed"

**Symptoms**: Step 1 fails at terraform validate

**Causes**:
- Invalid HCL syntax
- Missing variable definitions
- Undefined resources

**Fix**:
1. Check error message in logs
2. Run locally: `terraform validate`
3. Fix issues and push again

## Customization Guide

### Change Deployment Branch

Edit `.github/workflows/terraform-deploy.yml`:

```yaml
on:
  push:
    branches:
      - main          # Change to: staging, production, etc.
      - develop       # Add multiple branches
```

### Change Terraform Version

Edit workflow file:

```yaml
env:
  TERRAFORM_VERSION: "1.7.0"  # Change version number
```

### Change Workspace/Project

Edit workflow file:

```yaml
- name: Initialize Terraform
  run: |
    cd projects/project1/terraform     # Change path
    terraform init -upgrade
```

### Add Additional Validation

Edit workflow file:

```yaml
- name: Run Checkov (Security Scan)
  run: |
    pip install checkov
    checkov -d projects/project1/terraform
```

### Customize Cost Filtering

Edit workflow file:

```yaml
- name: Calculate Infrastructure Costs
  run: |
    infracost breakdown \
      --path=/tmp/tf-artifacts/tfplan.json \
      --format=json \
      --exclude-providers=data_sources    # Filter
```

### Send Slack Notifications

Add step to workflow:

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "Terraform deployment completed",
        "attachments": [{
          "color": "good",
          "fields": [{"title": "Status", "value": "✅ Applied"}]
        }]
      }
```

Add secret: `SLACK_WEBHOOK` with your Slack webhook URL

## Security Best Practices

### ✅ Enabled

1. **Federated Identity**: No long-lived secrets
2. **OIDC Tokens**: Time-limited tokens (6 hours)
3. **Approval Gate**: Manual review required
4. **Audit Logging**: Full GitHub Actions logs
5. **State Locking**: Prevents concurrent changes

### ⚠️ Recommended

1. **Branch Protection**:
   ```
   Settings → Branches → Add rule for "main"
   ✓ Require pull request reviews (2 reviewers)
   ✓ Dismiss stale pull request approvals
   ✓ Require branches up to be up to date
   ```

2. **Restrict Approval Power**:
   ```
   Only add DevOps/Infrastructure team as reviewers
   Rotate approvers periodically
   ```

3. **Monitor Deployments**:
   ```
   Regularly review:
   - Deployment logs
   - Approval history
   - Resource changes in Azure
   ```

4. **Secure State File**:
   ```
   terraform {
     backend "azurerm" {
       storage_account_name = "..."
       container_name       = "..."
       key                  = "..."
     }
   }
   ```

## Performance Optimization

### The workflow completes in:

- **Step 1**: 2-5 minutes (plan + costs)
- **Step 2**: 0 minutes (just approval)
- **Step 3**: 2-10 minutes (apply)

**Total approx**: 10-20 minutes from push to deployment complete

### To improve performance:

1. **Parallelize unrelated modules**:
   ```hcl
   # Break into smaller modules
   depends_on = [module.init]  # Explicitly order dependencies
   ```

2. **Cache Terraform providers**:
   ```yaml
   - uses: actions/cache@v3
     with:
       path: ~/.terraform.d/plugin-cache
       key: ${{ runner.os }}-terraform
   ```

3. **Limit resources**:
   ```hcl
   # Use for_each to create only needed resources
   for_each = var.create_keyvault ? [1] : []
   ```

## Disaster Recovery

### Recover from Failed Apply

```bash
# 1. Check error in logs
# 2. Fix issue in code
# 3. Commit and push
git add projects/project1/
git commit -m "fix: resolve terraform apply error"
git push origin main

# 4. Approve new deployment
# 5. Resources auto-corrected
```

### Manual Intervention (Emergency)

If pipeline fails and manual fix needed:

```bash
# 1. SSH to runner environment (custom runner only)
# 2. Manual terraform apply to fix
# 3. Update code to match state
# 4. Re-push to sync pipeline
```

### Resync Infrastructure State

```bash
# If state is out of sync with cloud
cd projects/project1/terraform

# Check state
terraform state list
terraform state show <resource>

# Refresh state from Azure
terraform refresh

# Re-import if needed
terraform import azurerm_resource_group.example /subscriptions/.../resourceGroups/rgName
```

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm)
- [Infracost Docs](https://www.infracost.io/docs/)
- [Azure OIDC Integration](https://learn.microsoft.com/en-us/azure/developer/github/)
