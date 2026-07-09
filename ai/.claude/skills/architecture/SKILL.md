---
name: architecture
description: |-
  Documents and maintains the architecture of the current codebase using the C4 model
  and Mermaid diagrams. Produces four separate files under docs/: System Context,
  Container, Component diagrams, and a design patterns catalogue. Renders each diagram
  with mcp__pencil after writing. Re-run at any time to update docs to reflect the
  current state of the code.
  Triggers: "document architecture", "architecture diagram", "update architecture",
  "C4 diagram", "system context", "container diagram", "component diagram",
  "design patterns", "architecture documentation", "keep architecture up to date".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Architecture Skill

## Goal

Analyze the current codebase and create or update four separate files under `docs/`
using Mermaid syntax. Render each diagram with `mmdc` after writing. Documentation
must accurately reflect actual code — never invent or assume components or patterns
that aren't evidenced.

## Output Files

| File | Content |
|------|---------|
| `docs/c4-context.md` | Level 1 – System Context diagram |
| `docs/c4-containers.md` | Level 2 – Container diagram |
| `docs/c4-components.md` | Level 3 – Component diagrams (one per non-trivial container) |
| `docs/architecture-patterns.md` | Design patterns catalogue with evidence |

Generate as many C4 levels as the codebase warrants. A small CLI may only need
Level 1–2; a microservices system likely needs all three. The patterns file is
always produced regardless of depth.

---

## Workflow

### Step 1: Check for existing documentation

Look for each of the four output files. If any exist, read them fully before
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

**Design patterns** — search source files for these indicators:

| Pattern | Category | Code signals |
|---------|----------|--------------|
| Repository | Structural | `*Repository`, `*Repo`, `*Store`, `Find*`/`Save*`/`Delete*` on domain types |
| Factory | Creational | `*Factory`, `Create*`, `New*`, `Make*` functions/classes |
| Singleton | Creational | `getInstance()`, `sync.Once`, module-level global instance |
| Builder | Creational | Fluent `With*()`/`Set*()` chains ending in `Build()`/`Create()` |
| Observer / Event | Behavioral | `EventEmitter`, `on('…', handler)`, pub/sub, event bus, `@EventHandler` |
| Strategy | Behavioral | Interface with multiple swappable implementations, injected behavior |
| Middleware / Decorator | Structural | `app.use()`, handler wrappers, HOCs, `@Decorator` annotations |
| Command / CQRS | Behavioral | `*Command`, `*Query`, `*Handler`, `Execute()`, separate read/write models |
| Facade | Structural | Single entry-point class/module hiding a complex subsystem |
| Adapter | Structural | `*Adapter`, `*Wrapper`, bridge between incompatible interfaces |
| Template Method | Behavioral | Abstract base class with `override`-able steps |
| State Machine | Behavioral | Explicit state enums + transition tables or state objects |
| Layered / N-Tier | Architectural | `controllers/` → `services/` → `repositories/` directory hierarchy |
| Hexagonal | Architectural | `domain/`, `ports/`, `adapters/` separation |
| Event Sourcing | Architectural | Append-only event log, `*Event`, replay/projection logic |
| MVC / MVP / MVVM | Architectural | Framework conventions: Rails, Spring MVC, Angular, ASP.NET |

For each pattern found: record the name, a one-sentence description of how it is
used in *this* codebase, and at least one file reference as evidence.

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

Process files in order: context → containers → components → patterns.

For **each C4 diagram file** (`c4-context.md`, `c4-containers.md`, `c4-components.md`):

1. **Create or update** using the diagram file template below
   - Creating: write the full template
   - Updating: replace only the Mermaid code block; preserve all surrounding text

2. **Render immediately** after writing:
   ```
   mmdc -i docs/<file>.md -o docs/<file>.png
   ```
   Show the rendered image to the user before moving to the next file.

For **`docs/architecture-patterns.md`**:

1. **Create or update** using the patterns file template below
   - Creating: write the full template with all patterns found
   - Updating: add new patterns, remove patterns no longer present, update evidence

2. No rendering needed — it contains no Mermaid diagrams.

#### Diagram file template

```markdown
<!-- architecture: auto-generated — edit the Mermaid block only, keep other text -->
# [Diagram Title]

> Last updated: YYYY-MM-DD

[One paragraph describing what this diagram shows. Manually maintained — not overwritten.]

```mermaid
C4Context   (or C4Container / C4Component)
  ...
```

<!-- manually maintained: add notes, decisions, or ADRs below this line -->
```

#### Patterns file template

```markdown
<!-- architecture: auto-generated -->
# Design Patterns

> Last updated: YYYY-MM-DD

Patterns identified in the codebase, with evidence.

| Pattern | Category | Usage in this codebase | Evidence |
|---------|----------|------------------------|----------|
| Repository | Structural | Abstracts database access for each domain entity | `src/repositories/UserRepository.ts:1` |
| Factory | Creational | ... | `...` |

<!-- manually maintained: extended notes below this line -->
```

### Step 5: Report the changes

After all files are written and rendered, tell the user:
- Which files were created vs updated
- Architectural elements added or removed since the last run
- Patterns added, removed, or updated
- Any gaps needing manual input (e.g. unclear external dependencies, unrecognised patterns)

---

## Rules

- **Only document what exists** — every element, relationship, and pattern must be
  evidenced by a specific file or code signal found during analysis
- **List every identified pattern** — `architecture-patterns.md` must enumerate all
  patterns found, with a usage description and at least one file:line reference each
- **Render after every C4 file write** — run `mmdc` immediately after each diagram
  file is written or edited, before moving on to the next file
- **Appropriate depth** — skip Level 3 for containers with trivial internals
- **Consistent naming** — use the same names as the codebase; do not rename things
- **Preserve manual text** — text outside the Mermaid block and content after
  `<!-- manually maintained -->` must never be overwritten
- **Accurate relationships** — only draw an arrow where there is code evidence
  of communication (import, HTTP call, DB connection, queue publish/consume)
- **Technology labels** — fill in the "Technology" field using the actual language,
  framework, or protocol found in the code

## Example Invocations

- `/architecture` — generate or refresh all four files (diagrams + patterns)
- `/architecture context only` — generate only the System Context diagram
- `/architecture update` — re-analyze codebase and update all files
- `/architecture patterns` — refresh only the design patterns catalogue
