# just-fucking-launch

Just fucking launch already.

A Claude Code-powered GTM toolkit. Go from idea to shipped product.

**Website:** [justfuckinglaunch.com](https://justfuckinglaunch.com)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│   FOUNDATION        COLLABORATION        BRAND        CONTENT        LAUNCH  │
│                                                                              │
│   ┌─────────┐       ┌───────────┐      ┌──────┐     ┌─────────┐    ┌─────┐   │
│   │Strategy │   →   │  Team     │  →   │Create│  →  │Generate │ →  │Ship │   │
│   │  Docs   │       │  Context  │      │Assets│     │Content  │    │ It  │   │
│   └─────────┘       └───────────┘      └──────┘     └─────────┘    └─────┘   │
│                                                                              │
│   vision            contributors       marks         threads       countdown │
│   narrative         suggestions        colors        articles      HUD       │
│   thesis            CRM               typography     one-pagers    launch    │
│   roadmap           tasks              website       decks                   │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## What This Does

Takes you from "we have an idea" to "we're launching" using Claude Code as your GTM co-pilot.

**The workflow:**
1. **Foundation** - Set up strategic docs that inform everything
2. **Collaboration** - Onboard contributors, manage tasks through conversation
3. **Brand** - Generate marks, colors, typography, preview in context
4. **Content** - Create threads, articles, one-pagers, decks
5. **Launch** - Track countdown, coordinate across team, ship

---

## The Pattern: Skill → Product → Launch

The most common use case: you build a Claude Code skill, then want to monetize it.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   SKILL (free)                          PRODUCT (paid)                      │
│   ──────────────                        ──────────────                      │
│   github.com/you/skill           →      yourproduct.io                      │
│                                                                             │
│   ├─ Claude Code skill                  ├─ Same functionality               │
│   ├─ Open source                        ├─ Better UX (web app)              │
│   ├─ Builds awareness                   ├─ Paywall ($5, $10, subscription)  │
│   └─ Shows it works                     └─ Monetizes                        │
│                                                                             │
│                     GTM TOOLKIT HELPS WITH:                                 │
│                     ├─ Brand (mark, name, colors)                           │
│                     ├─ Landing page assets                                  │
│                     ├─ Launch thread & content                              │
│                     ├─ One-pager for sharing                                │
│                     └─ Coordinate the launch                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Example pattern:** [just-fucking-cancel](https://github.com/rohunvora/just-fucking-cancel) → [justcancel.io](https://justcancel.io)
- Free skill builds awareness
- Paid product monetizes

**But this toolkit is for bigger plays:**

| What You're Building | Price Point | What You Need |
|---------------------|-------------|---------------|
| Micro-tool | $5-$20 | Just a landing page |
| **Serious product** | **$50-$200** | **Full GTM (this toolkit)** |
| SaaS / Platform | $200+/mo | Full GTM + ongoing campaign |

This toolkit gives you the whole system:
- Strategic foundation (vision, narrative, thesis)
- Brand identity (marks, colors, voice)
- Launch content (threads, articles, one-pagers)
- Team coordination (CRM, tasks, collaboration)
- Campaign tracking (HUD, countdown, milestones)

**You're not launching a $5 widget. You're launching a real product.**

## The Power

**Any team, any size, moves at the speed of Claude.**

- Solo founder? Claude is your GTM team.
- Small team? Everyone works from shared context.
- Growing team? Onboard people in minutes, not days.

**No context loss.** Every session builds on the last. Every contributor adds to the knowledge center. Every decision is recorded.

## Quick Start

**Requirements:** Claude Code + Claude Pro ($20/month)

```bash
# 1. Clone this repo
git clone https://github.com/402goose/just-fucking-launch.git
cd just-fucking-launch

# 2. Start Claude Code
claude

# 3. Tell Claude what you want
> Help me launch my product
```

Claude will walk you through setting up your vision, brand, and launch content.

Never used Claude Code? See the [Getting Started Guide](GETTING_STARTED.md).

## Folder Structure

```
just-fucking-launch/
├── CLAUDE.md                      # Claude Code instructions (THE BRAIN)
├── README.md                      # This file
│
├── knowledge/                     # YOUR strategic context (fill these out)
│   ├── VISION.md                 # What you're building, why it matters
│   ├── NARRATIVE.md              # How you tell the story
│   ├── THESIS.md                 # Investment/value thesis
│   ├── ROADMAP.md                # What ships when
│   ├── BRAND_BRIEF.md            # Brand inputs
│   ├── BRAND_DECISIONS.md        # Finalized brand choices
│   └── VOICE_AND_TONE.md         # How you speak
│
├── suggestions/                   # Contributor working space
│   └── {name}.md                 # Each person's suggestions/updates
│
├── internal/                      # Sensitive info (gitignored if needed)
│   ├── CRM.md                    # Contact details, strategies
│   └── LEADS.md                  # Active relationship plays
│
├── skills/                        # Claude Code skills
│   ├── campaign-hud/             # Status dashboard, countdown
│   ├── brand-architect/          # Generate marks, colors, typography
│   ├── web-architect/            # Implement assets, CSS, favicons
│   ├── content-creator/          # Threads, articles, one-pagers
│   └── crm-sync/                 # CRM through conversation
│
├── previews/                      # Real-world context previews
│   ├── brand/                    # Twitter profile, favicon, OG
│   ├── content/                  # Thread preview, article preview
│   └── print/                    # One-pager with PDF export
│
├── templates/                     # Starting templates
│   ├── strategic/                # Foundation docs
│   ├── brand/                    # Brand templates
│   └── collaboration/            # Contributor templates
│
├── outputs/                       # Generated assets
│   ├── svg/
│   ├── png/
│   └── css/
│
├── scripts/                       # Helper scripts
│   └── export-pngs.sh
│
└── examples/                      # Reference implementations
    └── 402-cat/                   # Complete GTM example
```

---

## Phase 1: Foundation

Before anything else, you need strategic clarity.

### Core Documents

| Document | Purpose | Template |
|----------|---------|----------|
| `VISION.md` | What you're building, why it matters | `templates/strategic/VISION.md` |
| `NARRATIVE.md` | How you tell the story, layers of messaging | `templates/strategic/NARRATIVE.md` |
| `THESIS.md` | Why this wins, investment case | `templates/strategic/THESIS.md` |
| `ROADMAP.md` | What ships when, milestones | `templates/strategic/ROADMAP.md` |

### How Claude Uses These

When someone asks "What do you do?", Claude pulls from VISION.md.
When someone asks "How do I explain this?", Claude pulls from NARRATIVE.md.
When someone asks "Why will this win?", Claude pulls from THESIS.md.

**Everything traces back to these docs.** Content, brand, messaging - all informed by the foundation.

---

## Phase 2: Collaboration

### The CLAUDE.md Pattern

Your `CLAUDE.md` is the brain. It tells Claude:

1. **Who's on the team** - Names, roles, permissions
2. **How to onboard** - Walk new people through the vision
3. **Where to route work** - Suggestions files for contributors
4. **How to track progress** - CRM and task updates through conversation

### Contributor Flow

```
New Contributor                        Returning Contributor
      │                                       │
      ▼                                       ▼
   Onboarding                            Quick catch-up
   (Vision walkthrough)                  (What changed)
      │                                       │
      ▼                                       ▼
   Profile capture                       Show their tasks
   (Strengths, time)                     (From last session)
      │                                       │
      ▼                                       ▼
   Assign tasks                          Continue working
      │                                       │
      └───────────────────┬───────────────────┘
                          │
                          ▼
                  Work gets saved to
                  suggestions/{name}.md
                          │
                          ▼
                  Owner reviews & merges
```

### CRM Through Conversation

Nobody types in spreadsheets. Updates happen naturally:

```
User: "I DMed @person and @other today"

Claude: "Got it. Logging:
- @person: DM_SENT
- @other: DM_SENT

What angle did you use?"
```

Updates queue in suggestions files. Owner syncs to master CRM.

---

## Phase 3: Brand

### Brand Architect Workflow

```bash
/brand-architect              # Full workflow
/brand-architect marks        # Generate mark options
/brand-architect colors       # Generate palettes
/brand-architect typography   # Font recommendations
```

### The Process

1. Fill out `knowledge/BRAND_BRIEF.md`
2. Run `/brand-architect` to generate options
3. Preview in `previews/brand/twitter-profile.html`
4. Record decisions in `knowledge/BRAND_DECISIONS.md`
5. Run `/web-architect implement all` to generate assets

### Outputs

- SVG marks (multiple sizes, dark/light)
- Favicons (16, 32, 48, 180, 192, 512px)
- Social assets (OG images, Twitter banners)
- CSS tokens (`outputs/css/global.css`)

---

## Phase 4: Content

### Content Creator Workflow

```bash
/content thread [topic]       # Twitter thread
/content post [topic]         # Single post
/content announce [what]      # Launch announcement
/content article [topic]      # Long-form article
/content one-pager [topic]    # Print-ready summary
/content deck [topic]         # Presentation slides
```

### Previews

- `previews/content/twitter-thread.html` - See threads in Twitter UI
- `previews/content/article-preview.html` - Blog-style preview
- `previews/print/one-pager.html` - Print/PDF export

### Voice Consistency

All content pulls from `knowledge/VOICE_AND_TONE.md`. Same voice across:
- Social posts
- Documentation
- Marketing copy
- Error messages

---

## Phase 5: Launch

### Campaign HUD

```bash
/hud                    # Full dashboard
/hud --compact          # One-line status
```

Shows:
- Days to launch
- Current phase
- This week's tasks
- Your assigned items
- Key metrics

### Launch Coordination

```
Week -4: Foundation (docs, brand)
Week -3: Assets (website, social)
Week -2: Content (threads, articles)
Week -1: Final push (announcements)
Launch:  Ship it
```

---

## Skills Reference

| Skill | Command | Purpose |
|-------|---------|---------|
| Campaign HUD | `/hud` | Status dashboard, countdown |
| Brand Architect | `/brand-architect` | Generate brand identity |
| Web Architect | `/web-architect` | Implement assets |
| Content Creator | `/content` | Generate content |
| CRM Sync | `/crm` | Manage contacts |

---

## Team Collaboration

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   Founder         GTM Lead         Designer         Dev         │
│      │               │                │              │          │
│      └───────────────┴────────────────┴──────────────┘          │
│                              │                                  │
│                      ┌───────▼───────┐                          │
│                      │  KNOWLEDGE    │                          │
│                      │    CENTER     │                          │
│                      │               │                          │
│                      │  Vision       │                          │
│                      │  Narrative    │                          │
│                      │  Brand        │                          │
│                      │  Voice        │                          │
│                      │  CRM          │                          │
│                      └───────────────┘                          │
│                              │                                  │
│                       Claude Code                               │
│                              │                                  │
│              ┌───────────────┼───────────────┐                  │
│              │               │               │                  │
│           Brand          Content         Campaign               │
│         Architect        Creator           HUD                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### How It Works

1. **Founder** sets vision, reviews decisions
2. **GTM Lead** coordinates campaign, manages CRM
3. **Designer** reviews brand options, makes decisions
4. **Dev** implements, builds assets
5. **Everyone** works from same context, no sync meetings needed

### Multi-Session Continuity

```
Session 1 (Founder):
├─ Set up vision docs
├─ Record initial decisions
└─ Outline roadmap

Session 2 (GTM Lead):
├─ All context preserved
├─ Add narrative layers
├─ Start CRM outreach
└─ Generate content

Session 3 (Designer):
├─ Review brand options
├─ Make mark decisions
├─ Generate assets
└─ Feedback recorded

Session 4 (Anyone):
├─ Full history available
├─ Continue where left off
└─ No re-explaining needed
```

---

## Example: 402.cat

See `examples/402-cat/` for a complete GTM implementation:

- Full knowledge center (vision, narrative, brand)
- CLAUDE.md with collaboration patterns
- Dual mark system (▲ ▲ + CAT wordmark)
- Generated assets (banners, favicons, OG)
- Voice and tone guide

---

## Philosophy

**Foundation first.** Strategy docs before tactics.

**Conversation is the interface.** No manual data entry.

**Context compounds.** Every session builds on the last.

**Decisions over options.** The goal is to ship, not explore forever.

**Speed of Claude.** Any team moves at conversation speed.

---

## Architecture & Advanced Patterns

### System Architecture

Want to understand how this all works under the hood?

See [ARCHITECTURE.md](ARCHITECTURE.md) for:
- Philosophy (conversation as interface, files as memory)
- Core components (strategic docs, skills, suggestions pattern)
- Collaboration modes (single-user, multi-user async, multi-session)
- Design decisions and trade-offs
- Cost & performance considerations
- Security best practices

### Building Skills & Agents

Want to extend this toolkit or build your own skills?

See [references/SKILL_FACTORY_PATTERNS.md](references/SKILL_FACTORY_PATTERNS.md) for:
- Skill structure and YAML frontmatter requirements
- Agent patterns (domain vs orchestration)
- When to use agents vs skills
- Optional YAML configuration for tooling/marketplace
- Multi-phase workflows and composition patterns
- Validation checklists

### Advanced Features (Optional)

The core workflow works great out of the box. These are optional enhancements for power users:

**Session Management Scripts** (Phase 3)
- Isolated git worktrees for parallel sessions
- Auto-commit safety nets
- Smart merge automation
- Recommended when running multiple sessions concurrently

**Campaign HUD CLI Tool** (Phase 4)
- Node.js tool for statusline integration
- Complements `/hud` skill with shell-based dashboard
- Modes: compact (one-liner), expanded (full box), JSON (programmatic)

**Agent Composition** (Phase 5)
- Templates and examples for building custom agents
- Domain expertise agents vs orchestration agents
- Multi-skill workflows

Coming soon - check back as these features roll out.

---

Built with Claude Code. adapted from the 402.cat launch campaign.
