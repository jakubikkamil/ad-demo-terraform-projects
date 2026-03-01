# GitHub Actions Terraform Pipeline - Quick Reference

## 🚀 Quick Start

### First Time Setup (5 min)

```bash
# 1. Create Azure Enterprise App & Federated Credentials
bash .github/AZURE_SETUP_SCRIPT.md  # Follow the script

# 2. Add GitHub Secrets
Settings → Secrets → Actions
  ✓ AZURE_CLIENT_ID
  ✓ AZURE_TENANT_ID
  ✓ AZURE_SUBSCRIPTION_ID

# 3. Create Protected Environment
Settings → Environments → New
  Name: gate-env
  Required reviewers: [Select your team]

# 4. Push workflow to main
git add .github/
git commit -m "ci: add terraform pipeline"
git push origin main
```

## 📋 Common Workflows

### Make Infrastructure Changes

```bash
# 1. Create feature branch
git checkout -b feature/add-storage

# 2. Edit terraform files
vim projects/project1/terraform/main.tf
vim projects/project1/ENVVARS/project1.json

# 3. Commit & push
git add projects/
git commit -m "feat: add storage account"
git push origin feature/add-storage

# 4. Create PR
# → GitHub auto-runs Step 1 (plan only)
# → Review PR comment with plan & costs
# → Approve & merge to main

# 5. On push to main
# → GitHub runs Step 1 (auto)
# → GitHub wait for approval Step 2
# → Open Actions → Review & approve
# → GitHub runs Step 3 (auto)
```

### Review a Plan Before Approving

```bash
# After push to main:
GitHub → Actions
→ Select workflow run
→ View "terraform-plan" job output
→ Review resource changes
→ Review estimated costs
→ "Review pending deployments"
→ "Approve and deploy"
```

### Cancel Deployment

```bash
# Before step 3 starts:
GitHub → Actions
→ Select workflow run
→ "Cancel workflow" button

# After step 3 starts:
# Cannot cancel (apply already running)
# Manual intervention in Azure required
```

### View Deployment Results

```bash
# After workflow completes:
GitHub → Actions
→ Select workflow run
→ View "terraform-apply" job
→ Check "Retrieve Outputs" section
→ Download "terraform-apply-logs" artifact
```

## 🔑 Environment Variables

| Variable | Source | Used In |
|----------|--------|---------|
| `AZURE_CLIENT_ID` | GitHub Secrets | All steps |
| `AZURE_TENANT_ID` | GitHub Secrets | All steps |
| `AZURE_SUBSCRIPTION_ID` | GitHub Secrets | All steps |
| `INFRACOST_API_KEY` | GitHub Secrets (optional) | Step 1 |
| `TERRAFORM_VERSION` | Workflow env | All steps |

## ⚙️ Workflow Triggers

| Event | Steps | Approval | Apply |
|-------|-------|----------|-------|
| **PR to main** | Step 1 only | N/A | No |
| **Push to main** | Steps 1→2→3 | Yes (Required) | Yes |
| **Manual trigger** | Not configured | N/A | N/A |

## 📊 Pipeline Status

### Step 1 - Plan & Costs
- ⏱️ Time: 2-5 minutes
- 🔍 Runs on: PR and push to main
- 📝 Output: PR comment, artifacts
- ✅ Status: Automatic

### Step 2 - Approval Gate
- ⏱️ Time: Variable (awaits approval)
- 🔍 Runs on: Push to main only
- 📝 Output: Deployment awaits approval
- ⏸️ Status: Manual approval

### Step 3 - Apply
- ⏱️ Time: 2-10 minutes
- 🔍 Runs on: Push to main (after approval)
- 📝 Output: Deployment report
- ✅ Status: Automatic

## 🐛 Troubleshoot

### "Authentication failed"
```bash
# Check secrets
Settings → Secrets → Actions
# Verify: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID

# Verify Azure credentials
az account show
```

### "Terraform validation failed"
```bash
# Check locally
cd projects/project1/terraform
terraform init
terraform validate

# Fix errors and retry
git add .
git commit -m "fix: terraform validation"
git push
```

### "Approval not showing"
```
Settings → Environments → gate-env
# Check: Protection rules enabled
# Check: Required reviewers configured
# Check: You are in reviewer list
```

### "Plan not found in Step 3"
```bash
# Artifacts may have expired (7 days)
# Trigger new deployment:
git commit --allow-empty -m "retry: terraform deployment"
git push origin main
```

## 📁 File Structure

```
.github/
  workflows/
    terraform-deploy.yml          # Main workflow
  GITHUB_ACTIONS_SETUP.md         # Detailed setup guide
  AZURE_SETUP_SCRIPT.md           # Azure CLI automation
  OPERATIONAL_GUIDE.md            # How to use guide
  QUICK_REFERENCE.md              # This file

projects/project1/
  terraform/
    main.tf                       # Terraform code
    variables.tf
    outputs.tf
    versions.tf
  ENVVARS/
    project1.json                 # Environment variables
```

## 🔐 Secrets Checklist

- [ ] AZURE_CLIENT_ID (from Azure)
- [ ] AZURE_TENANT_ID (from Azure)
- [ ] AZURE_SUBSCRIPTION_ID (from Azure)
- [ ] INFRACOST_API_KEY (optional, from https://dashboard.infracost.io)

## 👥 Environment Setup Checklist

- [ ] `gate-env` environment created
- [ ] Required reviewers added to `gate-env`
- [ ] Reviewer team has appropriate permissions in Azure
- [ ] Azure role assignments confirmed

## 📖 Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| `QUICK_REFERENCE.md` | This file - quick lookup | Everyone |
| `GITHUB_ACTIONS_SETUP.md` | Detailed setup & config | DevOps, Admins |
| `AZURE_SETUP_SCRIPT.md` | Azure automation | DevOps, Cloud Admins |
| `OPERATIONAL_GUIDE.md` | How to use pipeline | Everyone |

## 🆘 Getting Help

1. **Check documentation**:
   - OPERATIONAL_GUIDE.md → How to use
   - GITHUB_ACTIONS_SETUP.md → Setup issues
   - AZURE_SETUP_SCRIPT.md → Azure issues

2. **Review logs**:
   ```
   GitHub → Actions → [Run] → [Job] → View logs
   ```

3. **Common errors**:
   - Search "terraform validation failed" → Check HCL syntax
   - Search "authorization failed" → Check Azure credentials
   - Search "artifacts not found" → Check retention period

## 💡 Pro Tips

### Tip 1: Review Before Approving
```
GitHub → Actions → [Run]
→ Review Step 1 job logs
→ Download artifacts to inspect plan
→ THEN approve Step 2
```

### Tip 2: Keep State File Safe
```bash
# Backend should be:
terraform {
  backend "azurerm" {
    storage_account_name = "tfstate2024"    # Unique name
    container_name       = "tfstate"
    key                  = "prod.tfstate"
    resource_group_name  = "state-rg"
  }
}
```

### Tip 3: Add Cost Budget Alerts
```bash
# In Infracost step:
infracost breakdown \
  --format=json \
  --filter-providers=azure \
  --output-file=/tmp/cost.json

# Alert if monthly cost > threshold
COST=$(jq '.summary.totalMonthlyCost' /tmp/cost.json)
if (( $(echo "$COST > 5000" | bc -l) )); then
  echo "⚠️ Costs exceed budget: \$$COST"
fi
```

### Tip 4: Use Terraform Workspaces
```bash
# Deploy to multiple environments
terraform workspace new staging
terraform workspace select staging
terraform plan -var-file=staging.tfvars
```

### Tip 5: Schedule Regular Plan Reviews
```yaml
# Add to workflow for daily plan review
schedule:
  - cron: '0 9 * * MON'  # Every Monday 9 AM
```

## 🔄 Standard Deployment Checklist

```
☐ Pull latest main branch
☐ Create feature branch: git checkout -b feature/name
☐ Edit terraform files
☐ Test locally: terraform plan
☐ Commit changes
☐ Push to GitHub: git push origin feature/name
☐ Create Pull Request
☐ Wait for Step 1 (auto runs)
☐ Review PR comment:
  ☐ Check resource changes
  ☐ Verify costs
  ☐ Approve PR
☐ Merge to main
☐ Go to Actions tab
☐ Wait for approval notification
☐ Review "Review pending deployments"
☐ Click "Approve and deploy"
☐ Wait for Step 3 to complete
☐ Verify resources in Azure portal
☐ Monitor: Azure → Resource Groups → proj1-rg
```

## 📱 Slack Integration (Optional)

Add Slack notifications to workflow:

```yaml
- name: Notify Slack - Deployment Started
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
      -H 'Content-Type: application/json' \
      -d '{
        "text": "🚀 Terraform deployment started",
        "blocks": [{
          "type": "section",
          "text": {"type": "mrkdwn", "text": "*Status*: Planning"}
        }]
      }'

- name: Notify Slack - Awaiting Approval
  if: github.ref == 'refs/heads/main'
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
      -H 'Content-Type: application/json' \
      -d '{
        "text": "🔐 Terraform deployment awaiting approval"
      }'
```

Add to secrets: `SLACK_WEBHOOK` (from your Slack workspace)

## ⏱️ Approximate Timing

| Phase | Time | Notes |
|-------|------|-------|
| Checkout + Setup | 30s | Fixed time |
| Azure Auth | 10s | Fixed time |
| Terraform Init | 20-60s | Depends on provider cache |
| Terraform Plan | 1-2m | Depends on infrastructure size |
| Infracost | 30-60s | API call to estimate costs |
| PR Comment | 10s | Fixed time |
| **Total Step 1** | **2-5m** | Usually ~3m |
| Approval Gate | Variable | Human decision |
| Terraform Apply | 2-10m | Depends on Azure API speed |
| **Total Steps 2-3** | **2-10m+** | Depends on resources |
| **Total Pipeline** | **10-20m** | After approval |

## 🎯 Success Criteria

✅ Deployment is successful when:
- Step 1: ✓ Plan generated, costs calculated
- Step 2: ✓ Approved by authorized user
- Step 3: ✓ Resources deployed to Azure
- Outputs: ✓ Terraform outputs displayed
- Logs: ✓ Full audit trail in GitHub Actions

## 📞 Support

| Issue | Action |
|-------|--------|
| Workflow doesn't trigger | Check: Branch name, event trigger |
| Secrets not working | Check: Secret names exact match, values correct |
| Azure auth fails | Check: Federated credentials, role assignments |
| Approval not showing | Check: gate-env created, reviewer added |
| Plan fails | Check: HCL syntax, backend config |
| Apply fails | Check: Azure permissions, resource limits |

---

**Last Updated**: 2024
**Terraform Version**: 1.7.0+
**Azure Provider**: Latest
