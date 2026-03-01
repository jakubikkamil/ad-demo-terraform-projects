# Project Deployment on PR - Workflow Guide

## Overview

The `deploy_project_opr.yml` workflow automatically triggers Terraform deployments when a Pull Request is opened to the `main` branch. It intelligently extracts the project name from the PR title and passes it to the main deployment workflow.

## How It Works

```
PR Opened on main
    ↓
Extract project name from PR title
    ↓
Validate project directory exists
    ↓
Trigger terraform-deploy.yml with project name
    ↓
Step 1: Terraform Plan & Cost Analysis (automatic)
    ↓
Step 2: Approval Gate (manual approval)
    ↓
Step 3: Terraform Apply (after approval)
```

## PR Title Format

The workflow expects the PR title to follow this format:

```
Project Onboarding: <project-name>
```

Or alternatively:

```
project: <project-name>
```

### Examples

✅ **Valid PR Titles**:
- `Project Onboarding: test4`
- `Project Onboarding: production-api`
- `Project: my_app`
- `project: e-commerce`
- `Project Onboarding: web-app-v2`

❌ **Invalid PR Titles**:
- `Add test4 to infrastructure` (missing "Project Onboarding:" prefix)
- `Project Onboarding:` (no project name)
- `Project Onboarding: test@app` (invalid characters in project name)
- `Project Onboarding: test4 new features` (spaces after project name)

## Creating a PR to Trigger Deployment

### Step 1: Make Infrastructure Changes

```bash
# Create feature branch
git checkout -b feature/add-storage

# Make changes to terraform
vim projects/test4/terraform/main.tf
vim projects/test4/ENVVARS/test4.json

# Commit changes
git add projects/test4/
git commit -m "feat: add storage account to test4"
```

### Step 2: Create Pull Request with Correct Title

```bash
# Push to origin
git push origin feature/add-storage

# Create PR with title format: "Project Onboarding: <project-name>"
# Go to GitHub → Create Pull Request
# Title: "Project Onboarding: test4"
# Description: Any additional notes
```

### Step 3: Workflow Automatically Triggers

When you create the PR:

1. **Extraction Phase**:
   - Workflow extracts "test4" from PR title
   - Validates project directory exists
   - Validates terraform directory exists
   - Validates ENVVARS file exists

2. **Deployment Phase**:
   - Calls `terraform-deploy.yml` with project="test4"
   - Runs Step 1 (Terraform Plan & Cost Analysis)
   - Prepares Step 2 (Approval Gate)

3. **Approval Phase**:
   - Review workflow run
   - Check Terraform plan
   - Review cost estimates
   - When ready, approve deployment

4. **Apply Phase**:
   - Step 3 automatically applies configuration
   - Updates infrastructure in Azure

## Project Directory Requirements

For the workflow to find your project, ensure this structure exists:

```
projects/
├── test4/                          # Project name (extracted from PR title)
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── (other terraform files)
│   └── ENVVARS/
│       └── test4.json              # Must match project name
└── projectX/
    ├── terraform/
    └── ENVVARS/
```

## Project Name Rules

Project names must:
- ✅ Contain only alphanumeric characters, hyphens, and underscores
- ✅ Match the directory name in `projects/`
- ✅ Match the JSON filename in `projects/<project>/ENVVARS/`
- ❌ Not contain spaces, special characters, or uppercase letters
- ❌ Not exceed reasonable length

### Valid Project Names
- `test4`
- `project1`
- `web-api`
- `my_app`
- `prod_env_v2`

### Invalid Project Names
- `Test4` (uppercase)
- `web app` (space)
- `web@api` (special char)
- `web-api!` (special char)

## Workflow Execution Details

### Job 1: Extract Project Name

**What it does**:
1. Reads PR title: "Project Onboarding: test4"
2. Extracts project name: "test4"
3. Validates format (alphanumeric, hyphens, underscores)
4. Checks project directory exists
5. Checks terraform directory exists
6. Checks ENVVARS file exists

**Output**: `project-name=test4`

### Job 2: Deploy Terraform

**What it does**:
1. Calls `.github/workflows/terraform-deploy.yml`
2. Passes `project=test4`
3. Runs all 3-step deployment process

**Environment**: Uses inherited secrets for Azure authentication

### Job 3: Deployment Summary

**What it does**:
1. Summarizes workflow execution
2. Shows project name and status
3. Provides next steps for approval

## Monitoring the Deployment

### View Workflow Run

```
GitHub → Actions
→ Select "Deploy Project on PR" workflow
→ Find the run matching your PR number
→ Click to view logs
```

### Check Each Step

1. **Extract Project & Deploy**
   - Confirms project name extraction
   - Validates project directory

2. **Deploy Terraform**
   - Shows Terraform plan
   - Shows cost estimates
   - Waits for approval

3. **Deployment Summary**
   - Shows overall status
   - Confirms successful deployment

## Troubleshooting

### Error: "Could not extract project name from PR title"

**Cause**: PR title doesn't match expected format

**Fix**: Update PR title to format:
```
Project Onboarding: <project-name>
```

**Example**:
```
❌ Wrong: "Add new infrastructure"
✅ Right: "Project Onboarding: test4"
```

### Error: "Project directory not found"

**Cause**: Project directory doesn't exist

**Fix**: Create project structure:
```bash
mkdir -p projects/test4/terraform
mkdir -p projects/test4/ENVVARS
touch projects/test4/ENVVARS/test4.json
# Add terraform files...
```

### Error: "Invalid project name format"

**Cause**: Project name contains invalid characters

**Fix**: Use only alphanumeric, hyphens, underscores:
```
❌ Invalid: "test@app", "test app", "TEST4"
✅ Valid: "test4", "test-app", "test_app"
```

### Workflow Didn't Trigger

**Cause**: PR not opened on `main` branch

**Fix**:
1. Ensure PR target branch is `main`
2. New PR was created (not existing PR updated)
3. Workflow file exists: `.github/workflows/deploy_project_opr.yml`

## Advanced Usage

### Multiple Projects

To deploy a different project, simply create a new PR with a different title:

**PR 1** - Deploy test4:
```
Title: "Project Onboarding: test4"
→ Workflow extracts "test4"
→ Deploys projects/test4/
```

**PR 2** - Deploy staging:
```
Title: "Project Onboarding: staging"
→ Workflow extracts "staging"
→ Deploys projects/staging/
```

Each PR gets its own independent deployment workflow.

### Environment-Specific Configuration

Use different ENVVARS files for different environments:

```
projects/myapp/
├── terraform/
│   ├── main.tf (same for all envs)
│   ├── variables.tf (same for all envs)
│   └── ...
└── ENVVARS/
    └── myapp.json (environment-specific config)
```

Update the JSON file for different configurations:
- Database size
- Network settings
- Backup retention
- Cost optimization

### Workflow Integration

This workflow works with:
- **terraform-deploy.yml**: Main 3-step deployment
- **approval-gate environment**: Requires approval before apply
- **Azure authentication**: Uses federated identity
- **Infracost**: Shows cost estimates

## Best Practices

1. **PR Title Consistency**
   - Always use format: "Project Onboarding: project_name"
   - Be specific about the project being deployed

2. **Code Review**
   - Have terraform changes reviewed before merge
   - Verify plan looks correct
   - Review cost estimates in workflow

3. **Approval Process**
   - Assign required reviewers
   - Document approval rationale
   - Keep approval records

4. **Project Naming**
   - Use lowercase names
   - Use hyphens for multi-word names
   - Keep names short and descriptive
   - Example: `web-api`, `mobile-app`, `data-pipeline`

5. **ENVVARS Configuration**
   - Keep sensitive values in Azure Key Vault
   - Version control non-sensitive configs
   - Test locally before deployment

## Related Documentation

- [Terraform Deploy Workflow](./terraform-deploy.yml)
- [Project Structure](../projects/README.md)
- [Blueprint Modules](../blueprints/README.md)
- [GitHub Actions Setup Guide](.././GITHUB_ACTIONS_SETUP.md)

## Common Workflow Patterns

### Pattern 1: Single Project Deployment

```
1. Make infrastructure changes in projects/web-api/
2. Create PR: "Project Onboarding: web-api"
3. Workflow automatically triggers
4. Review terraform plan
5. Approve deployment
6. Infrastructure deployed
```

### Pattern 2: Multi-Project Scaling

```
1. Create projects/web-api/, projects/api-gateway/, projects/database/
2. Create PR: "Project Onboarding: web-api"
   → Deploys web-api
3. Create PR: "Project Onboarding: api-gateway"
   → Deploys api-gateway
4. Create PR: "Project Onboarding: database"
   → Deploys database
```

### Pattern 3: Environment Progression

```
1. Create projects/myapp-dev/, projects/myapp-staging/, projects/myapp-prod/
2. Deploy to dev: PR "Project Onboarding: myapp-dev"
3. Test in dev
4. Deploy to staging: PR "Project Onboarding: myapp-staging"
5. Test in staging
6. Deploy to prod: PR "Project Onboarding: myapp-prod"
```

## Support

For issues or questions:
1. Check workflow logs: Actions → Run → View logs
2. Verify project structure
3. Verify PR title format
4. Review terraform plan output
5. Check approval status in gate-env environment

---

**Remember**: PR title format is critical! 🔑
```
Project Onboarding: <project-name>
```
