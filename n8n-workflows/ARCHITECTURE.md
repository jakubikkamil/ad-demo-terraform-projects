# Technical Architecture

## Workflow Design Patterns

### Event Flow Diagram

```
Chat Trigger (webhook)
    ↓
Define Repository & Branch (configuration)
    ↓
Fetch variables.tf (HTTP GET)
    ↓
Validate & Guide Agent (LLM)
    ↓
Check Validation Status (switch/route)
    ├─ needs_clarification → Chat Response
    ├─ needs_approval → Chat Response  
    └─ complete → GitHub Integration
```

---

## Node-by-Node Configuration

### Phase 1: Input & Parsing

#### `Chat Trigger`
- **Type**: `@n8n/n8n-nodes-langchain.chatTrigger`
- **Webhook ID**: `c666cd74-ff01-4d1e-b25f-2930df3d56dd`
- **Output**: `chatInput`, `sessionId`
- **Connects To**: `Define Repository & Branch`

#### `Define Repository & Branch`
- **Type**: `n8n-nodes-base.set`
- **Configuration**:
  ```json
  {
    "branchName": "sql",
    "repositoryName": "jakubikkamil/ad-demo-terraform-projects"
  }
  ```
- **Purpose**: Hardcoded repository configuration
- **⚠️ Customization Point**: Update for different repository
- **Connects To**: `Fetch variables.tf`

#### `Fetch variables.tf`
- **Type**: `n8n-nodes-base.httpRequest`
- **Authentication**: GitHub OAuth2 API
- **URL Pattern**:
  ```
  https://raw.githubusercontent.com/{repositoryName}/{branchName}/projects/project1/terraform/variables.tf
  ```
- **Purpose**: Retrieve variable schema
- **Connects To**: `Validate & Guide Agent`

---

### Phase 2: Validation

#### `Validate & Guide Agent`
- **Type**: `@n8n/n8n-nodes-langchain.agent`
- **Model**: OpenAI Chat (gpt-4-mini)
- **System Prompt Logic**:
  1. Parse variables.tf schema
  2. Analyze user request
  3. Extract project_name, environment, modules
  4. Return structured JSON

**Output**:
- `status`: complete | needs_clarification | needs_approval
- `intent`: deployment_request | infrastructure_question | mixed
- `summary`: Description
- `follow_up_questions`: Array
- `validated_spec`: Canonical JSON (if complete)

#### `Conversation Memory`
- **Type**: `@n8n/n8n-nodes-langchain.memoryBufferWindow`
- **Context Window**: 10 messages
- **Purpose**: Maintain conversation history

#### `Check Validation Status`
- **Type**: `n8n-nodes-base.switch`
- **Routes**:
  - **complete** → File retrieval phase
  - **needs_approval** → Approval request
  - **needs_clarification** → Ask for more info

---

### Phase 3: File Retrieval

#### `Get Project1 File Tree`
- **Type**: `n8n-nodes-base.httpRequest`
- **URL**: GitHub Tree API with recursive flag
- **Output**: Array of files with SHA

#### `Extract File Paths`
- **Type**: `n8n-nodes-base.code`
- **Map**: `projects/project1/terraform/*` → `projects/{projectName}/terraform/*`

#### `Split File Paths`
- **Type**: `n8n-nodes-base.splitOut`
- **Purpose**: Create individual items per file

#### `Fetch File Content`
- **Type**: `n8n-nodes-base.httpRequest`
- **For Each**: File item
- **Output**: Base64-encoded content

#### `Decode and Prepare Files`
- **Type**: `n8n-nodes-base.code`
- **Logic**:
  - Base64 decode
  - Customize backend.tf (update state key)
  - Output: `[{ path, content }]`

#### `Code in JavaScript`
- **Type**: `n8n-nodes-base.code`
- **Purpose**: Generate ENVVARS configuration JSON

---

### Phase 4: Git Operations

#### `Create New Branch`
- **Type**: `n8n-nodes-base.httpRequest`
- **Method**: POST /git/refs
- **Body**: `{ ref: "refs/heads/feature/...", sha: mainSha }`

#### `Create Tree`
- **Type**: `n8n-nodes-base.httpRequest`
- **Method**: POST /git/trees
- **Format files**: mode: "100644", type: "blob"

#### `Create Commit`
- **Type**: `n8n-nodes-base.httpRequest`
- **Method**: POST /git/commits
- **Atomic**: Single commit with all files

#### `Update Branch Reference`
- **Type**: `n8n-nodes-base.httpRequest`
- **Method**: PATCH /git/refs/heads/{branch}
- **Point branch to new commit**

#### `Create Pull Request`
- **Type**: `n8n-nodes-base.httpRequest`
- **Method**: POST /repos/.../pulls
- **Includes**: Files list and validated spec

---

## Error Handling Strategy

### Node-Level Configuration

#### `onError: continueErrorOutput`
- Continue even on HTTP errors
- Useful for optional checks

#### Route-Based Errors
```javascript
if (response.status === 404) {
  // Safe to create
  return items;
} else if (response.status === 200) {
  // Project exists - error
  throw new Error(`Project already exists`);
}
```

---

## Data Flow & State Management

### Session State
```
Chat Trigger (sessionId)
    ↓
Conversation Memory (stores 10 messages)
    ↓
Each message context available to agent
```

### File State Progression
```
Raw File (GitHub)
    ↓
Base64-Encoded
    ↓
Decoded to Text
    ↓
Customized (backend.tf)
    ↓
Grouped in Tree
    ↓
Committed to Git
    ↓
PR Created
```

---

## Performance Characteristics

### Time Complexity
- **Validation**: O(1) - Single LLM call
- **File Fetching**: O(n) - One HTTP per file
- **Git Operations**: O(1) - Constant calls

### Network Requests
1. Fetch variables.tf
2. Validate via LLM
3. Check project exists
4. Check branches
5. Get file tree
6. Fetch each file (n requests)
7. Git operations (7 requests)

**Total**: ~n + 15 requests

### Typical Execution Time
- Validation: 3-5 seconds
- File retrieval: 5-10 seconds
- Git operations: 5-8 seconds
- **Total**: 15-30 seconds (5-10 files)

---

## Authentication & Security

### GitHub OAuth2
1. User clicks Test workflow
2. Redirected to GitHub
3. Grants access
4. Token stored securely in n8n

### Credential Security
- Encrypted in database
- Never in logs or PRs
- Auto-rotated by n8n

### API Rate Limiting
- GitHub: 5,000 reqs/hour
- OpenAI: Depends on plan
- Per-workflow: ~15-25 requests

---

## Customization Guide

### Change Repository
1. Edit: `Define Repository & Branch`
2. Update: `repositoryName` variable
3. Verify: Branch exists

### Use Different LLM
1. Edit: `Validate & Guide Agent`
2. Change: Model selector
3. Update: System prompt if needed

### Add Custom Validation Rules
1. Edit: System prompt
2. Add: New validation logic
3. Test: With sample inputs

### Extend to Multiple Templates
1. Add: User template selection
2. Modify: File tree retrieval
3. Update: Path mapping logic

---

## Troubleshooting

### Debug Mode Logging
1. Workflow settings → Execution data
2. Set: Save execution data = All
3. Check: Executions tab

### Common Issues

#### LLM Returns Invalid JSON
- Cause: Context too large
- Fix: Reduce variables.tf or increase tokens

#### GitHub API 403
- Cause: Token expired
- Fix: Re-authenticate

#### Branch Creation Fails
- Cause: Base branch doesn't exist
- Fix: Verify repository settings

#### Missing Fields in Validation
- Cause: LLM hallucination
- Fix: Revise system prompt

---

**Last Updated**: March 2026  
**Workflow Version**: 1.0
