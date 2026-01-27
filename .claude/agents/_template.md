---
name: your-agent-name
description: One sentence describing what this agent does and when to use it
tools: Read, Write, Edit, Bash, Grep, Glob  # Comma-separated, never arrays
model: sonnet  # sonnet | haiku | opus
color: blue  # blue (strategic) | green (implementation) | red (quality) | purple (coordination)
field: your-domain  # e.g., content, design, blockchain, marketing
expertise: expert  # expert | intermediate
mcp_tools:  # Optional - only if needed
  - mcp__tool_name
---

# Agent: {Your Agent Name}

> One-line description of what this agent does

## When to Invoke

Describe the situations that should trigger this agent:

- Specific user requests that match this domain
- Natural language patterns that indicate this agent should activate
- Contextual triggers (e.g., "when working on content", "during launch phase")

## Capabilities

List what this agent can do:

- ⚡ Capability 1 with emoji
- 🎯 Capability 2 with emoji
- 🚀 Capability 3 with emoji

## Domain Type

**[Domain Agent | Orchestration Agent]**

- **Domain Agent:** Deep expertise in a specific area, responds to natural language
- **Orchestration Agent:** Multi-phase workflow coordinator

## Workflow / Phases

### For Domain Agents

Describe the typical workflows in this domain:

**Workflow 1: [Name]**
1. Step 1
2. Step 2
3. Step 3

**Workflow 2: [Name]**
1. Step 1
2. Step 2

### For Orchestration Agents

Describe the phases:

**Phase 1: [Name] (Assessment)**
- What happens in this phase
- What gets evaluated
- Decision points

**Phase 2: [Name] (Planning)**
- What gets planned
- User approval gates
- What gets documented

**Phase 3: [Name] (Execution)**
- What gets executed
- Safety checks
- Progress tracking

**Phase 4: [Name] (Verification)**
- How success is verified
- What gets reported
- Follow-up actions

## Tools & Skills Used

List the tools and skills this agent leverages:

**Claude Code Tools:**
- Read - For reading context files
- Write - For creating new files
- Edit - For modifying existing files
- Bash - For git operations (if needed)
- Grep/Glob - For finding files

**Skills:**
- `/skill-name` - What it's used for
- `/another-skill` - What it's used for

**MCP Tools (if applicable):**
- `mcp__tool_name` - What it does

**Configuration Files:**
- `path/to/config.yaml` - Purpose
- `path/to/data.json` - Purpose

## Context Files

Files this agent typically reads for context:

**Required:**
- `knowledge/VISION.md` - For understanding project vision
- `knowledge/NARRATIVE.md` - For brand voice

**Optional:**
- `knowledge/ROADMAP.md` - For timeline context
- `knowledge/TASKS.md` - For current priorities

## Safety & Approval Gates

Describe when user approval is needed:

**Always require approval for:**
- Destructive operations (deletes, overwrites)
- External API calls that cost money
- Publishing/deploying to production
- Changes to core strategic documents

**No approval needed for:**
- Read operations
- Local file creation
- Analysis and reporting
- Draft generation

## Success Criteria

How do you know this agent succeeded?

- [ ] Success criterion 1
- [ ] Success criterion 2
- [ ] Success criterion 3
- [ ] All outputs generated
- [ ] User satisfied with results

## Example Invocations

**Example 1:**
```
User: "Help me with [specific task]"

Agent:
1. Does this
2. Then this
3. Finally this

Result: [What gets produced]
```

**Example 2:**
```
User: "I need [specific outcome]"

Agent:
1. Assesses [something]
2. Plans [something]
3. Executes [something]

Result: [What gets produced]
```

## Limitations

What this agent CANNOT do:

- Limitation 1
- Limitation 2
- Limitation 3

When users need these, direct them to:
- Alternative agent or skill
- Manual process
- External tool

## Error Handling

How this agent handles common errors:

**Error Type 1:**
- What causes it
- How agent responds
- What user should do

**Error Type 2:**
- What causes it
- How agent responds
- What user should do

## Agent Composition

**This agent can be used by other agents:**

Example of how another agent might use this agent's capabilities:

```markdown
## In Another Agent

When needing [this agent's capability]:

1. Read `.claude/agents/your-agent-name.md` for workflows
2. Load configuration from [config files]
3. Follow the same [patterns/safety rules]
4. Report results in context
```

**This agent uses these other agents:**

- `other-agent-name` - For what capability
- `another-agent` - For what capability

## Configuration

If this agent has configuration files, document them:

### config/your-config.yaml

```yaml
agent_config:
  setting1: value
  setting2: value
```

**Fields:**
- `setting1` - What it controls
- `setting2` - What it controls

## References

- Link to related documentation
- Link to external resources
- Link to examples

---

## Development Notes

Notes for maintaining/improving this agent:

- Known issues
- Future improvements
- Performance considerations
