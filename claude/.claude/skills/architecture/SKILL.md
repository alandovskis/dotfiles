---
name: architecture
description: |-
  Documents and maintains the architecture of the current codebase using the C4 model
  and Mermaid diagrams. Produces three separate files (System Context, Container,
  Component) under docs/, rendering each with mcp__pencil after writing. Re-run at
  any time to update diagrams to reflect the current state of the code.
  Triggers: "document architecture", "architecture diagram", "update architecture",
  "C4 diagram", "system context", "container diagram", "component diagram",
  "architecture documentation", "keep architecture up to date".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - mcp__pencil
---

# Architecture Skill

## Goal

Analyze the current codebase and create or update three separate C4 diagram files
under `docs/` using Mermaid syntax. Render each diagram with `mcp__pencil` after
writing. Documentation must accurately reflect actual code — never invent or assume
components that aren't evidenced.

## Output Files

| File | C4 Level | Content |
|------|----------|---------|
| `docs/c4-context.md` | Level 1 | System Context diagram |
| `docs/c4-containers.md` | Level 2 | Container diagram |
| `docs/c4-components.md` | Level 3 | Component diagrams (one per non-trivial container) |

Generate as many levels as the codebase warrants. A small CLI may only need
Level 1–2; a microservices system likely needs all three.

---

## Workflow

### Step 1: Check for existing documentation

Look for each of the three output files. If any exist, read them fully before
proceeding — preserve manually written text (descriptions, notes, ADRs) when updating.

### Step 2: Analyze the codebase

Use these signals to reverse-engineer the architecture:

**Project type and language**
- `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `pom.xml`, `build.gradle`
- Identify framework: Express, Spring Boot, FastAPI, Gin, Rails, etc.

**Deployment topology**
- `docker-compose*.yml` — services, their names, networks, and port mappings
- `Dockerfile*` — what each container runs
- `kubernetes/`, `k8s/`, `helm/` — deployed workloads
- `terraform/`, `pulumi/` — infrastructure components

**Internal structure**
- Top-level directory layout
- Entry points: `main.*`, `cmd/`, `app.*`, `index.*`, `server.*`
- Module boundaries: `internal/`, `pkg/`, `src/`, `lib/`, `services/`, `modules/`
- Config files: `.env.example`, `config/`, `application.yml`, `config.yaml`

**External integrations** — search for these patterns in source files:
- Database drivers: postgres, mysql, sqlite, mongodb, redis, dynamodb, elasticsearch
- Message queues: kafka, rabbitmq, sqs, nats, pubsub, amqp
- HTTP clients calling external URLs (look for base URLs in env/config)
- Cloud SDK imports: aws-sdk, @google-cloud, azure-sdk, boto3
- Auth providers: oauth, cognito, auth0, keycloak, okta, passport
- Payment/comms: stripe, twilio, sendgrid, mailgun

**API boundaries**
- REST routes: `router.`, `app.get(`, `@GetMapping`, `r.Handle`, `path(`
- gRPC: `*.proto` files
- GraphQL: `*.graphql`, `schema.graphql`, `typeDefs`
- WebSocket handlers

### Step 3: Build the diagrams

Use Mermaid's native C4 syntax. Every element and relationship must be backed by
evidence found in Step 2.

#### C4Context — Level 1

```
C4Context
  title [System Name] – System Context

  Person(personAlias, "Label", "Description")
  Person_Ext(extPersonAlias, "Label", "Description")

  System(systemAlias, "Label", "Description")
  System_Ext(extAlias, "Label", "Description")
  SystemDb_Ext(dbAlias, "Label", "Description")

  Rel(from, to, "Label")
  Rel(from, to, "Label", "Technology")
  BiRel(a, b, "Label")
```

#### C4Container — Level 2

```
C4Container
  title [System Name] – Container Diagram

  Person(personAlias, "Label", "Description")

  System_Boundary(boundaryAlias, "System Name") {
    Container(apiAlias, "Label", "Technology", "Description")
    ContainerDb(dbAlias, "Label", "Technology", "Description")
    ContainerQueue(queueAlias, "Label", "Technology", "Description")
  }

  System_Ext(extAlias, "Label", "Description")

  Rel(from, to, "Label")
  Rel(from, to, "Label", "Technology")
```

#### C4Component — Level 3

One diagram per container that has meaningful internal structure (skip trivial ones).

```
C4Component
  title [Container Name] – Component Diagram

  Container_Boundary(boundaryAlias, "Container Name") {
    Component(compAlias, "Label", "Technology", "Description")
    ComponentDb(dbAlias, "Label", "Technology", "Description")
  }

  Container_Ext(extAlias, "Label", "Technology", "Description")
  System_Ext(extAlias, "Label", "Description")

  Rel(from, to, "Label")
  Rel(from, to, "Label", "Technology")
```

### Step 4: Write or update each file, then render

Process the three files in order: context → containers → components.

For **each file**:

1. **Create or update** the file using the template below
   - Creating: write the full template
   - Updating: replace only the Mermaid code block; preserve all surrounding text

2. **Render immediately** after writing by calling `mcp__pencil` on the file,
   so the user sees the rendered diagram before moving to the next file

#### File template

Each of the three files follows this structure:

```markdown
<!-- c4-docs: auto-generated — edit the Mermaid block only, keep other text -->
# [Diagram Title]

> Last updated: YYYY-MM-DD

[One paragraph describing what this diagram shows. Manually maintained — not overwritten.]

```mermaid
C4Context   (or C4Container / C4Component)
  ...
```

<!-- manually maintained: add notes, decisions, or ADRs below this line -->
```

### Step 5: Report the changes

After all files are written and rendered, tell the user:
- Which files were created vs updated
- Architectural elements added or removed since the last run
- Any gaps needing manual input (e.g. unclear external dependencies)

---

## Rules

- **Only document what exists** — every element and relationship must be evidenced
  by a specific file or code pattern found during analysis
- **Render after every write** — call `mcp__pencil` immediately after each file
  is written or edited, before moving on to the next file
- **Appropriate depth** — skip Level 3 for containers with trivial internals
- **Consistent naming** — use the same names as the codebase; do not rename things
- **Preserve manual text** — text outside the Mermaid block and content after
  `<!-- manually maintained -->` must never be overwritten
- **Accurate relationships** — only draw an arrow where there is code evidence
  of communication (import, HTTP call, DB connection, queue publish/consume)
- **Technology labels** — fill in the "Technology" field using the actual language,
  framework, or protocol found in the code

## Example Invocations

- `/architecture` — generate or refresh all three diagram files
- `/architecture context only` — generate only the System Context diagram
- `/architecture update` — re-analyze codebase and update all diagrams
