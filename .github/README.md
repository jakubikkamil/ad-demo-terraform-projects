# Terraform GitHub Actions Pipeline

Enterprise-grade GitHub Actions pipeline for automated infrastructure deployment to Azure using Terraform, with cost analysis and approval workflows.

## 📋 Features

✅ **Automated Planning**
- Terraform plan generation
- Infrastructure validation
- Cost estimation with Infracost

✅ **Approval Workflow**
- Manual approval gate (`gate-env`)
- Authorized reviewer requirement
- Audit trail of all approvals

✅ **Secure Deployment**
- Azure federated identity (no secrets)
- OIDC token-based authentication
- Role-based access control
- State locking during apply

✅ **Comprehensive Reporting**
- PR comments with plan summaries
- Infrastructure cost breakdowns
- Deployment outputs
- Artifact retention

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│          Git Push/Pull Request               │
└──────────────┬─────────────────────────────┘
               │
        ┌──────▼──────┐
        │  Step 1:    │  ✓ Terraform plan
        │  Plan &     │  ✓ Infracost estimate
        │  Costs      │  ✓ PR comment
        └──────┬──────┘
               │
        ┌──────▼──────┐
        │  Step 2:    │  ⏳ Awaiting approval
        │  Approval   │     (gate-env)
        │  Gate       │
        └──────┬──────┘
               │
        ┌──────▼──────┐
        │  Step 3:    │  ✓ Terraform apply
        │  Deploy     │  ✓ Outputs
        │             │  ✓ Report
        └──────┬──────┘
               │
        ✅ Infrastructure Deployed
```

## 🚀 Quick Start

### 1. Prerequisites

- GitHub repository access
- Azure subscription with Owner/Contributor role
- Azure CLI installed (for setup)

### 2. Setup (5 minutes)

```bash
# 1. Run Azure setup
bash .github/AZURE_SETUP_SCRIPT.md

# 2. Copy secrets to GitHub
# Settings → Secrets → Actions → Add secrets

# 3. Create protected environment
# Settings → Environments → Create "gate-env"

# 4. Push workflow to repository
git add .github/workflows/terraform-deploy.yml
git commit -m "ci: add terraform pipeline"
git push origin main
```

**Detailed instructions**: See [GITHUB_ACTIONS_SETUP.md](./.github/GITHUB_ACTIONS_SETUP.md)

### 3. First Deployment

```bash
# Make terraform changes
git checkout -b feature/my-changes
# ... edit projects/project1/terraform/* ...
git add projects/project1/
git commit -m "feat: add infrastructure"
git push origin feature/my-changes

# Create PR → Step 1 runs automatically
# Merge PR → Push to main
# Steps 2 & 3 run with approval required
```

**Operational guide**: See [OPERATIONAL_GUIDE.md](./.github/OPERATIONAL_GUIDE.md)

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **QUICK_REFERENCE.md** | One-page lookup for common tasks |
| **GITHUB_ACTIONS_SETUP.md** | Detailed setup & configuration guide |
| **AZURE_SETUP_SCRIPT.md** | Azure CLI automation & manual steps |
| **OPERATIONAL_GUIDE.md** | Complete how-to guide with examples |

### Where to Start?

- 👤 **First time?** → Start with [QUICK_REFERENCE.md](./.github/QUICK_REFERENCE.md)
- 🔧 **Setting up?** → See [AZURE_SETUP_SCRIPT.md](./.github/AZURE_SETUP_SCRIPT.md)
- 📖 **How to use?** → Read [OPERATIONAL_GUIDE.md](./.github/OPERATIONAL_GUIDE.md)
- ⚙️ **Need details?** → Check [GITHUB_ACTIONS_SETUP.md](./.github/GITHUB_ACTIONS_SETUP.md)

## 🔄 Workflow Details

### Step 1: Plan & Cost Analysis (Automatic)

```
Checkout → Setup Terraform & Infracost
  ↓
Azure Login (Federated Identity)
  ↓
Terraform Init → Validate → Plan
  ↓
Infracost Cost Estimation
  ↓
Generate PR Comment / Save Artifacts
```

**Duration**: 2-5 minutes
**Triggers**: PR to main, Push to main
**Approval needed**: No

### Step 2: Approval Gate (Manual)

```
Wait for Approval
  ↑
🔐 Protected Environment (gate-env)
  ↓
  Only authorized reviewers can approve
```

**Duration**: Variable (human decision)
**Triggers**: Push to main only
**Approval needed**: Yes

### Step 3: Apply (Automatic after Approval)

```
Download Plan Artifacts
  ↓
Azure Login (Federated Identity)
  ↓
Terraform Apply
  ↓
Collect Outputs → Generate Report
```

**Duration**: 2-10 minutes
**Triggers**: After Step 2 approval
**Approval needed**: No

## 🔐 Security

### Authentication
- **Method**: Azure Federated Identity (OpenID Connect)
- **No secrets stored**: Uses temporary OIDC tokens
- **Token lifetime**: 6 hours (GitHub Actions)

### Authorization
- **Azure**: Enterprise Application with role assignments
- **GitHub**: Protected environment with required reviewers
- **Approval**: Authorized users only

### Audit Trail
- GitHub Actions logs (all steps)
- Approval history (gate-env)
- Terraform state locking
- Azure activity logs

## 📊 Cost Management

The pipeline tracks infrastructure costs using **Infracost**:

```yaml
- Shows monthly cost estimates
- Breaks down by resource type
- Compares with baseline (optional)
- Post in PR comments
```

**Cost display** in PR comments:
```
💰 Estimated Monthly Cost: $1,234.56
  └─ Storage: $50
  └─ Key Vault: $100
  └─ Other: $1,084.56
```

Set optional `INFRACOST_API_KEY` secret for detailed analysis.

## 🛠️ Configuration

### Change Deployment Path

Edit `.github/workflows/terraform-deploy.yml`:

```yaml
- name: Initialize Terraform
  run: |
    cd projects/project1/terraform  # Change this path
    terraform init -upgrade
```

### Change Terraform Version

```yaml
env:
  TERRAFORM_VERSION: "1.7.0"  # Update version
```

### Add Approval Notifications

Add Slack/Teams notification in workflow yml:

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {"text": "Deployment awaiting approval"}
```

### Customize Infracost

Modify cost estimation in workflow:

```yaml
infracost breakdown \
  --path=/tmp/tf-artifacts/tfplan.json \
  --format=json \
  --compare-to=master
```

## 📋 Workflows

### Scenario: Add Storage Account

```
1. Feature branch → Edit terraform
2. Commit & push → Create PR
3. GitHub runs Step 1 (automatic)
4. Review PR comment with plan
5. Approve & merge to main
6. GitHub runs Step 1 again
7. GitHub waits (Step 2) → Approval
8. Reviewer approves
9. GitHub runs Step 3 → Resources deployed
10. Verify in Azure portal
```

### Scenario: Fix & Redeploy

```
1. Issue detected in deployment
2. Fix in code → Create new PR
3. Merge → Push to main
4. GitHub runs new plan (Step 1)
5. Review & approve
6. Resources updated (Step 3)
```

## 📦 Artifacts

The pipeline saves artifacts for:

| Artifact | Retention | Purpose |
|----------|-----------|---------|
| `terraform-plan-artifacts` | 7 days | Plan files, cost estimates |
| `terraform-apply-logs` | 30 days | Deployment logs |

Download from: **Actions → [Run] → Artifacts**

## ✅ Checklist

Before first deployment:

- [ ] Azure Enterprise App created
- [ ] Federated credentials configured
- [ ] GitHub secrets added (3 required)
- [ ] `gate-env` environment created
- [ ] Required reviewers assigned
- [ ] `.github/workflows/terraform-deploy.yml` pushed
- [ ] Test deployment triggered

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Azure auth failed" | Check secrets: Settings → Secrets |
| "Plan not found in Step 3" | Artifacts may have expired (7d) |
| "Terraform validation failed" | Check HCL syntax locally |
| "Approval not showing" | Check gate-env environment settings |

See **[OPERATIONAL_GUIDE.md](./.github/OPERATIONAL_GUIDE.md)** for detailed troubleshooting.

## 📞 Support & References

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Azure OIDC Integration](https://learn.microsoft.com/en-us/azure/developer/github/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm)
- [Infracost Documentation](https://www.infracost.io/docs/)

## 📝 Next Steps

1. **Setup**: Follow [AZURE_SETUP_SCRIPT.md](./.github/AZURE_SETUP_SCRIPT.md)
2. **Configure**: Add GitHub secrets and environment
3. **Test**: Make a test commit to main
4. **Review**: Check Actions tab for workflow status
5. **Deploy**: Approve deployment when ready

## 📄 License

Same as repository

## 🤝 Contributing

To update the pipeline:

1. Edit `.github/workflows/terraform-deploy.yml`
2. Test in feature branch
3. Create PR for review
4. Merge to main after approval

---

**Pipeline Version**: 1.0
**Terraform**: 1.7.0+
**Azure Provider**: 3.x+
**Updated**: 2024
