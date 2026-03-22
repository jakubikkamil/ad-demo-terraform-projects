# N8N Workflows Documentation

## Overview

This folder contains N8N automation workflows for infrastructure orchestration and Terraform project management.

### Available Workflows

1. **AI Terraform Project Scaffolder with GitHub PR Automation**

---

## AI Terraform Project Scaffolder with GitHub PR Automation

**Workflow ID:** 3dzkFU6aQQreqASX

### Purpose

This workflow automates the creation of new Terraform projects through an interactive chat interface. It validates user requirements against an existing Terraform variables schema, creates project files, commits them to GitHub, and automatically generates pull requests for review.

### Key Features

- 🤖 **AI-Powered Validation** - Uses LLM agents to understand user requests
- ✅ **Schema Validation** - Validates inputs against existing Terraform variables.tf
- 🌿 **Git Integration** - Creates branches and commits atomically
- 🔄 **PR Automation** - Automatically generates pull requests with summaries
- 💬 **Conversational Interface** - Interactive chat-based user experience
- 🛡️ **Error Handling** - Comprehensive duplicate detection and validation
- 💾 **State Management** - Maintains conversation context across interactions

### Workflow Architecture

#### Phase 1: Input & Validation

Chat Trigger → Define Repository & Branch → Fetch variables.tf → Validate & Guide Agent → Check Validation Status

**Components:**
- **Chat Trigger**: Receives user input via n8n chat interface
- **Define Repository & Branch**: Sets target repository and branch (hardcoded to jakubikkamil/ad-demo-terraform-projects / sql)
- **Fetch variables.tf**: Retrieves the canonical variables.tf from GitHub
- **Validate & Guide Agent**: OpenAI/Gemini LLM validates user request
- **Conversation Memory**: Maintains context window of 10 messages

**Validation Statuses:**
- `needs_clarification` - Missing or ambiguous information
- `needs_approval` - All required data present, awaiting confirmation
- `complete` - Fully validated, ready for deployment

#### Phase 2: File Retrieval & Git Operations

Check Project Folder → Check Branch → Get File Tree → Fetch Files → Create Commit → Create PR

**Components:**
- **Check Project Folder Exists**: Validates project doesn't already exist
- **Get Project1 File Tree**: Retrieves template files from projects/project1/terraform/
- **Fetch File Content**: Downloads each file from GitHub
- **Create Tree/Commit/PR**: Atomic Git operations

#### Phase 3: Response Routing

Based on validation status, routes to appropriate response node.

### Input/Output Data Models

#### Chat Trigger Input
```json
{
  "chatInput": "user's natural language request",
  "sessionId": "conversation session ID"
}
```

#### Validation Agent Output
```json
{
  "status": "complete | needs_clarification | needs_approval",
  "intent": "deployment_request | infrastructure_question | mixed",
  "summary": "user-friendly summary",
  "follow_up_questions": ["array of numbered questions"],
  "validated_spec": {
    "project_name": "string",
    "modules": ["array of module names"],
    "environment": "string",
    "config": { "terraform variables" }
  }
}
```

### Configuration & Setup

#### GitHub Credentials
- Uses OAuth2 authentication
- Requires: `n8n-nodes-base.githubOAuth2Api`
- Credential ID: `OVFEPWnbJS1BwHOl`

#### LLM Models
- **Primary**: OpenAI GPT-4.1-mini
- **Fallback**: Google Gemini (PaLM)

#### Repository Configuration
```
Repository: jakubikkamil/ad-demo-terraform-projects
Target Branch: sql
Template Location: projects/project1/terraform/
Projects Location: projects/{project-name}/terraform/
```

### Error Handling

| Scenario | Response |
|----------|----------|
| Project exists | Error message + project name |
| Branch conflicts | Error with existing branch |
| Validation failures | Clarification questions |

### File Processing

1. **Base64 Decoding**: Converts GitHub API response to text
2. **backend.tf Customization**: Updates state file key
3. **ENVVARS Generation**: Creates configuration file

### Usage Examples

#### Create New Project
```
User: "Create a project called my-app in dev environment with storage and keyvault"

Flow:
1. Chat Trigger receives request
2. Validation Agent extracts and validates
3. Returns summary for approval
4. Branch, files, and PR created
```

### Limitations

1. **Hardcoded Repository** - Currently fixed to specific repo
2. **Single Template** - Uses project1 as template
3. **Sequential File Fetching** - One at a time
4. **No Workspace Locking** - Could have conflicts

### Related Resources

- Variables Schema: points/project1/terraform/variables.tf
- Template Files: projects/project1/terraform/
- Generated PRs: Created to specified branch

---

## Security Considerations

- GitHub credentials stored securely in n8n
- All API requests authenticated with OAuth2
- File contents validated before commit
- User input sanitized by LLM agent

## Performance Notes

- Average execution time: 15-30 seconds
- API calls: ~15 GitHub API requests per deployment
- Token usage: ~2,000 tokens per validation
