# Agents Directory

This directory contains **agent definitions** for your GTM campaign.

---

## What Are Agents?

**Agents** are multi-phase workflows that can run autonomously, make decisions, and trigger skills. They're more sophisticated than skills.

### Agent vs Skill

| Aspect | Skill | Agent |
|--------|-------|-------|
| **Invocation** | User calls explicitly | User calls or triggers automatically |
| **Workflow** | Single linear workflow | Multi-phase with branching |
| **Decision Making** | Follows steps | Makes autonomous choices |
| **Duration** | Quick (seconds to minutes) | Can run longer, background capable |
| **Complexity** | Simple, focused task | Complex orchestration |

---

## Agent Types

### 1. Domain Agents

**Conversational interface to a capability domain**
- Respond to natural language in their domain
- No slash commands needed
- Deep expertise in specific areas (blockchain, marketing, design)
- Example: blockchain-expert, content-strategist

**When to create:**
- You need specialized domain knowledge
- Natural language interaction is preferred
- Multiple workflows in the same domain

### 2. Orchestration Agents

**Multi-phase workflows with decision points**
- Complex orchestration across multiple skills
- Can run autonomously
- Phase-based execution with approval gates
- Example: campaign-coordinator, launch-orchestrator

**When to create:**
- Complex multi-step workflows
- Need to coordinate multiple skills/agents
- Approval gates between phases

---

## Agent Structure

Each agent file follows the Claude Code agent pattern:

```markdown
---
name: agent-name
description: One-line purpose
tools: Read, Write, Edit, Bash, Grep, Glob
model: sonnet | haiku | opus
color: blue | green | red | purple
field: domain-area
expertise: expert | intermediate
mcp_tools: mcp__tool_name  # Optional
---

# Agent: {name}

## When to Invoke
[Situations that trigger this agent]

## Capabilities
[What the agent can do]

## Phases
### Phase 1: [Name]
[What happens in this phase]

### Phase 2: [Name]
[What happens in this phase]

## Tools & Skills Used
[Tools and skills this agent leverages]

## Success Criteria
[How you know the agent succeeded]
```

### Agent Categories

| Category | Color | Purpose | Tool Pattern |
|----------|-------|---------|--------------|
| Strategic | blue | Planning, research, analysis | Read/Write/Grep (parallel OK) |
| Implementation | green | Code writing, building | Full access (coordinated) |
| Quality | red | Testing, validation | Heavy Bash (sequential ONLY) |
| Coordination | purple | Orchestration | Lightweight tools |

---

## When to Create an Agent vs Skill

**Create a Skill when:**
- Single focused workflow
- Deterministic steps
- User needs to call it explicitly
- Quick execution
- Reusable component

**Example:** `/hud`, `/content thread`, `/brand-architect`

**Create an Agent when:**
- Multi-phase workflow with decision points
- Needs to orchestrate multiple skills
- Can run autonomously or in background
- Complex problem requiring exploration
- Conditional branching logic

**Example:** campaign-coordinator (plan → execute → verify)

---

## Agent Composition

**Agents can use other agents' capabilities!** This enables powerful composition patterns.

### How It Works

Agents are instructions for Claude's behavior in specific contexts. When one agent needs capabilities from another domain:

1. **Reference the domain agent** - Read the agent file to understand workflows
2. **Use shared configuration** - Access the same config files
3. **Follow the same patterns** - Respect safety rules, approval gates
4. **Report in context** - Show results within your agent's workflow

### Example: Campaign Coordinator Using Domain Experts

```markdown
# Campaign Coordinator Agent

## Launch Phase

When executing launch:

1. **Content generation**
   - Read `.claude/agents/content-strategist.md` for content workflows
   - Follow brand voice rules
   - Generate launch thread, announcement

2. **Tech deployment**
   - Read `.claude/agents/tech-coordinator.md` for deployment workflow
   - Verify all systems ready
   - Execute deployment with approval gates

3. **Outreach execution**
   - Use outreach patterns from domain agent
   - Coordinate multi-channel launch
   - Track engagement
```

### Benefits

1. **No duplication** - Don't recreate domain logic
2. **Consistent safety** - Same approval gates across all agents
3. **Shared configuration** - Single source of truth
4. **Focused agents** - Each agent masters one domain, composes for complex tasks

### Which Agents Are Composable?

| Agent Type | Composable? | How Others Use It |
|------------|-------------|-------------------|
| **Domain agents** | ✅ Yes | Reference workflows, use configs, follow patterns |
| **Orchestration agents** | 🔶 Partial | Can reference patterns, but orchestration is specific |

**Domain agents** are highly composable.
**Orchestration agents** are less composable - they're end-to-end workflows.

---

## Best Practices

### For Agents

1. **Clear phases** - Break complex work into distinct phases
2. **Approval gates** - Ask user before major changes
3. **Use skills** - Compose from existing skills when possible
4. **State management** - Track phase progress
5. **Error handling** - Graceful degradation, clear errors

### For Naming

- Agents: `noun-noun` or `domain-role` (e.g., `content-strategist`, `campaign-coordinator`)
- Skills: `verb` or `noun` (e.g., `sync`, `hud`, `content`)

### For Documentation

- Always include "When to Invoke" section
- Document all phases clearly
- List tools and skills used
- Provide success criteria

---

## Integration with Skills

**Agents can call skills:**

```
campaign-coordinator agent:
  Phase 1: Plan
    → Uses planning logic
  Phase 2: Execute
    → Calls /hud (check status)
    → Calls /content (generate content)
    → Implements changes
  Phase 3: Verify
    → Uses verification logic
```

**Skills cannot call agents** (only users can trigger agents)

---

## Creating Your First Agent

See `_template.md` for a complete agent template.

See `examples/` for reference implementations:
- `domain-agent-example.md` - Domain expert pattern
- `orchestration-agent-example.md` - Multi-phase orchestrator

---

## Example Agents for GTM Campaigns

Potential agents for your campaign:

### Domain Agents
- **content-strategist** - Content generation with brand voice
- **brand-guardian** - Ensure brand consistency across all assets
- **outreach-coordinator** - Manage multi-channel outreach

### Orchestration Agents
- **campaign-coordinator** - Orchestrate full campaign execution
- **launch-orchestrator** - Coordinate launch day activities
- **post-launch-monitor** - Track and respond to launch metrics

---

## References

- `../../ARCHITECTURE.md` - System design, why we have agents and skills
- `../../CLAUDE.md` - How Claude uses agents in conversation
- `../../references/SKILL_FACTORY_PATTERNS.md` - Advanced patterns for agents and skills
- Individual agent files - Detailed agent documentation

---

**Agents = Autonomous orchestrators. Skills = Focused tools.**
