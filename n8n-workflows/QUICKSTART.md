# Quick Start Guide

## AI Terraform Project Scaffolder

### What This Workflow Does

Automates creation of new Terraform projects through a conversational chat interface. You describe what you want, the AI validates it, and it automatically creates a GitHub PR with all your infrastructure code.

### Getting Started (5 minutes)

#### Step 1: Deploy the Workflow

1. Open n8n instance
2. Go to **Workflows** → **Import**
3. Upload the workflow JSON file
4. Click **Import**

#### Step 2: Configure Credentials

The workflow needs GitHub and LLM access:

**GitHub OAuth2:**
- Click ⚙️ (settings)
- Navigate to **Credentials**
- Create new credential: `GitHub OAuth2 API`
- Follow GitHub app authorization

**OpenAI API:**
- Create new credential: `OpenAI API`
- Enter your API key

#### Step 3: Customize Repository

Edit node: **Define Repository & Branch**
```
Update to your repository:
- branchName: your-target-branch (e.g., "main")
- repositoryName: your-org/your-repo
```

#### Step 4: Start Using

1. Click **Test workflow**
2. Chat trigger opens
3. Type: `Create a project named my-terraform with dev environment`
4. Follow the prompts

### Common Commands

#### Create New Project
```
"Create a new project called [name] in [environment] with [resources]"

Examples:
- "Create project: my-app, environment: production, modules: storage + keyvault"
- "Scaffold my-infra in dev with available resources"
```

#### Ask Infrastructure Questions
```
"What modules are available?" 
"What's the naming convention?"
"Can I use these resources together?"
```

### Response Statuses

| Status | Meaning | Next Step |
|--------|---------|-----------|
| ❓ Questions | Need more info | Answer follow-up questions |
| ✅ Review | All info ready | Confirm to proceed |
| ❌ Exists | Duplicate project | Use different name |
| ✨ Committed | Success | Check GitHub for PR |

### What Gets Created

After approval:

1. **New Git Branch**: `feature/{project-name}-{timestamp}`
2. **Files**: Copied from template
3. **Configuration**: ENVVARS JSON file
4. **Pull Request**: Automatic PR with summary

### Example Conversation

```
You: "I need infrastructure for dev environment"

Bot: ❓ I need clarification:
- Project name?
- Which modules? (storage, keyvault, networking)
- Location?

You: "acme-dev, storage and keyvault"

Bot: ✅ Review:
- Project: acme-dev
- Modules: storage, keyvault
Approve?

You: "Yes"

Bot: ✨ Files Committed!
- Branch: feature/acme-dev-20260322-143022
- PR: https://github.com/your-org/repo/pull/42
```

### Troubleshooting

#### "Project Already Exists"
Choose a different project name or delete the existing one

#### Bot Keeps Asking Questions
Provide project name, environment, and modules in one message

#### PR Not Created
GitHub credentials may be expired - re-authenticate

#### Branch Already Has This Name
Delete old branch or use different project name

### Advanced Configuration

#### Use Different LLM
Edit: **Validate & Guide Agent**
- Change model selector dropdown

#### Change Template Location
Edit: **Get Project1 File Tree**
- Update URL path

#### Set Up Multiple Instances
Duplicate workflow and change `Define Repository & Branch` settings

### Performance Tips

- Use GPT-4 mini (default) for faster responses
- Be specific in initial request
- Create projects one at a time

---

**Happy Automating! 🚀**
