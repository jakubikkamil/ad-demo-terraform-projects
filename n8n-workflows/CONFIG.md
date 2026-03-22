# Workflow Configuration Reference

## Environment Variables

The workflow uses hardcoded configuration that should be customized for your environment:

```json
{
  "Define Repository & Branch": {
    "branchName": "sql",
    "repositoryName": "jakubikkamil/ad-demo-terraform-projects"
  }
}
```

### Update These Values

| Variable | Current | Purpose | Example |
|----------|---------|---------|---------|
| `branchName` | `sql` | Target branch for projects | `main`, `develop` |
| `repositoryName` | `jakubikkamil/ad-demo-terraform-projects` | GitHub repository | `myorg/terraform-infra` |
| Template path | `projects/project1/terraform/` | Source template | `blueprints/standard` |
| Project path | `projects/{projectName}/terraform/` | Destination | `infrastructure/{name}` |

---

## Credentials Configuration

### Required Credentials

#### 1. GitHub OAuth2 API
```
Provider: GitHub
Flow: OAuth2 Authorization Code
Scope: repo, workflow
Credential ID: OVFEPWnbJS1BwHOl
```

**Setup Steps:**
1. Go to GitHub → Settings → Developer Settings → OAuth Apps
2. Create New OAuth App
   - Application name: `n8n Terraform Scaffolder`
   - Homepage URL: `https://your-n8n-instance.com`
   - Authorization callback URL: `https://your-n8n-instance.com/rest/oauth2/callback`
3. Copy: Client ID and Client Secret
4. In n8n: Create new GitHub OAuth2 credential
5. Link to workflows

**Required Permissions:**
- `repo` - Repository access
- `workflow` - GitHub Actions access

#### 2. OpenAI API
```
Provider: OpenAI
Model: gpt-4-mini
Credential ID: TgOG3ISKREkbDiyH
```

**Setup Steps:**
1. Get API key from https://platform.openai.com/api-keys
2. In n8n: Create new OpenAI API credential
3. Paste: API key
4. Link to workflow

**Cost Estimate:**
- ~2,500 tokens per validation
- ~$0.002-0.004 per execution
- ~$1-2 for 500 projects

#### 3. Google Gemini API (Optional Fallback)
```
Provider: Google PaLM API
Credential ID: AJ2KfUKAWnhJ6YW5
```

**Setup Steps:**
1. Get API key from https://makersuite.google.com/app/apikey
2. Create new Google PaLM credential
3. Link to workflow

---

## Node Configuration Details

### LLM Model Selection

**Current Setup:**
- Primary: OpenAI GPT-4.1-mini
- Fallback: Google Gemini

**To Change:**
1. Edit: `Validate & Guide Agent` node
2. Click: Model dropdown
3. Select: Different model

**Supported Models:**
| Model | Cost | Speed | Accuracy | Context |
|-------|------|-------|----------|---------|
| GPT-4 | High | Fast | Excellent | 8k |
| GPT-4-mini | Low | Fast | Very Good | 8k |
| Claude 3 Haiku | Low | Fast | Good | 100k |
| Gemini Pro | Low | Fast | Good | 30k |

**Recommendation:** GPT-4-mini (balances cost and quality)

### System Prompt Configuration

**Location:** `Validate & Guide Agent` node → Options → systemMessage

**Key Instructions:**
- Parse variables.tf schema
- Match user request to resources
- Return VALID JSON ONLY
- Ask clarifying questions
- Follow validation rules from comments
- Maintain user-friendly tone

**To Customize:**
1. Add constraints (e.g., require approval for production)
2. Add naming rules (e.g., enforce kebab-case)
3. Add resource limits (e.g., max 5 storage accounts)
4. Add approval workflows

### Context Window Configuration

**Current:** 10 messages in memory

**To Change:**
1. Edit: `Conversation Memory` node
2. Update: `contextWindowLength` parameter

**Considerations:**
- Larger = Better context, higher tokens
- Smaller = Cheaper, faster, less history
- Recommended: 5-15 messages

---

## GitHub API Endpoints Used

```
GET  /repos/{owner}/{repo}/contents/{path}
     Check if project folder exists

GET  /repos/{owner}/{repo}/branches
     List all branches

GET  /repos/{owner}/{repo}/git/trees/{branch}?recursive=1
     Get all files recursively

GET  /repos/{owner}/{repo}/git/blobs/{sha}
     Fetch file content (base64)

GET  /repos/{owner}/{repo}/git/refs/heads/{branch}
     Get branch HEAD reference

GET  /repos/{owner}/{repo}/git/commits/{sha}
     Get commit details

POST /repos/{owner}/{repo}/git/refs
     Create new branch

POST /repos/{owner}/{repo}/git/trees
     Create file tree object

POST /repos/{owner}/{repo}/git/commits
     Create commit

PATCH /repos/{owner}/{repo}/git/refs/heads/{branch}
      Update branch reference

POST /repos/{owner}/{repo}/pulls
     Create pull request
```

### Rate Limiting

**GitHub Limits:**
- Authenticated: 5,000 requests/hour
- Reset: Hourly
- Per-workflow: ~15-25 requests

**Safe Concurrency:** ~200 concurrent workflows

**Monitor:** Check `X-RateLimit-Remaining` header

---

## Data Structure Reference

### Validated Specification Output

**When `status: "complete"`:**

```json
{
  "validated_spec": {
    "project_name": "acme-prod",
    "environment": "production",
    "modules": ["storage", "keyvault", "networking"],
    "config": {
      "resource_group_name": "rg-acme-prod",
      "location": "eastus",
      "create_storage_account": true,
      "create_key_vault": true,
      "tags": {
        "environment": "production"
      }
    }
  }
}
```

**Required Fields:**
- `project_name`
- `environment`
- `modules`
- `config`

---

## Error Response Reference

### Validation Errors

#### Missing Required Information
```json
{
  "status": "needs_clarification",
  "summary": "I found missing information.",
  "follow_up_questions": [
    "Required: Project name?",
    "Required: Which modules?",
    "Optional: Location?"
  ]
}
```

#### Project Already Exists
```json
{
  "status": 200,
  "message": "Project already exists"
}
```

#### GitHub Branch Conflict
```json
{
  "name": "feature/acme-dev-20260322",
  "status": "error",
  "message": "Branch already exists"
}
```

### HTTP Error Responses

| Code | Cause | Handling |
|------|-------|----------|
| 401 | Invalid credentials | Re-authenticate |
| 403 | Rate limited | Wait & retry |
| 404 | Resource not found | Expected for non-existent projects |
| 422 | Validation failed | Check request format |
| 500 | Server error | Retry with backoff |

---

## Monitoring & Logging

### Key Logs to Check

1. **Input Validation**
   - Chat Trigger payload
   - Variable parsing results

2. **LLM Processing**
   - Prompt sent
   - Token usage
   - Model response
   - Parsing results

3. **GitHub Operations**
   - API response codes
   - Rate limit remaining
   - File content size

### Performance Metrics

**To Monitor:**
- Execution duration: < 60 seconds
- LLM tokens: < 5,000 per execution
- GitHub API calls: 15-25 per project
- Success rate: > 95%
- Error rate: < 5%

### Debug Tips

1. **Enable Execution Data:**
   - Settings → Execution data
   - Save: All

2. **Add Logging:**
   ```javascript
   console.log('Processing:', $json.projectName);
   console.log('Files:', files.length);
   ```

3. **Test Individual Nodes:**
   - Settings → Test modes
   - Run: Individual nodes

4. **Check Rate Limits:**
   - Headers: `X-RateLimit-Remaining`

---

## Scalability Considerations

### Single Instance Limits

**Current Setup:**
- ~1,000 projects/day
- ~5,000 GitHub API calls/day
- ~$2-5/day in OpenAI costs

**Bottlenecks:**
- GitHub API rate limits
- OpenAI token costs
- n8n execution queue

### High-Volume Scaling

**For 1,000+ daily executions:**

1. **Implement Queuing:**
   - Add task queue

2. **Parallel Execution:**
   - Multiple n8n instances
   - Load balancer

3. **Caching:**
   - Cache variables.tf (5 min TTL)
   - Cache LLM responses

4. **Batching:**
   - Batch file fetches
   - Parallel GitHub calls

### Resource Requirements

**Per Instance:**
- CPU: 2+ cores
- Memory: 2+ GB
- Disk: 10+ GB
- Network: 100+ Mbps

**For 100 concurrent users:**
- CPU: 8+ cores
- Memory: 8+ GB
- Database: PostgreSQL 12+

---

## Maintenance Tasks

### Daily
- Monitor success rate
- Check error logs
- Verify GitHub credentials

### Weekly
- Review execution metrics
- Audit PR creation
- Test end-to-end

### Monthly
- Update variables.tf
- Rotate credentials
- Review costs

### Quarterly
- Security audit
- Dependency updates
- Performance check
- User feedback

---

## Backup & Recovery

### What to Backup

1. **Workflow Definition:**
   - Export JSON regularly
   - Store in version control
   - Include all node configs

2. **Credential Keys:**
   - Backup securely (encrypted)
   - Separate location
   - Rotate quarterly

3. **Execution History:**
   - Archive monthly
   - Database dumps
   - Logs in cloud storage

### Recovery Procedure

**If Workflow Corrupted:**
1. Stop executions
2. Export backup JSON
3. Delete current workflow
4. Import backup
5. Verify nodes
6. Resume requests

**If Credentials Lost:**
1. Regenerate GitHub OAuth
2. Create new n8n credentials
3. Update nodes
4. Test auth

---

## Cost Optimization

### Current Cost Breakdown

**Per Project Creation:**
- OpenAI: ~$0.003-0.005
- GitHub: Free (included)
- n8n: ~$0.01
- **Total: ~$0.02 per project**

### Cost Reduction

1. **Use Cheaper LLM:**
   - Switch to Gemini or Haiku

2. **Cache Data:**
   - Cache variables.tf
   - Cache branch lists

3. **Optimize Tokens:**
   - Reduce file size
   - Summarize requirements
   - Cache responses

### Budget Estimation

| Scenario | Daily | Monthly | Yearly |
|----------|-------|---------|--------|
| 10 projects | $0.20 | $6 | $73 |
| 100 projects | $2.00 | $60 | $730 |
| 1,000 projects | $20.00 | $600 | $7,300 |

---

**Last Updated:** March 22, 2026  
**Version:** 1.0
