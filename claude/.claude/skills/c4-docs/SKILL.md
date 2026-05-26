---
name: c4-docs
description: |-
  Creates and maintains C4 architecture documentation using Mermaid diagrams.
  Analyzes the codebase to generate accurate System Context, Container, and Component
  diagrams written to ARCHITECTURE.md. When run on a project that already has
  ARCHITECTURE.md, updates the diagrams to reflect current code state while
  preserving any manually written sections.
  Triggers: "document architecture", "create C4 docs", "update architecture diagram",
  "generate system diagram", "C4 model", "architecture documentation", "keep docs up to date".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# C4 Architecture Documentation Skill

## Goal

Analyze the current codebase and create or update `ARCHITECTURE.md` with C4-model
architecture diagrams using Mermaid syntax. Documentation must accurately reflect
actual code — never invent or assume components that aren't evidenced.

## C4 Model Overview

| Level | Diagram | Focus |
|-------|---------|-------|
| 1 | **System Context** | The system + external actors and systems |
| 2 | **Container** | Deployable units: services, databases, queues, frontends |
| 3 | **Component** | Internals of a single container |

Generate as many levels as the codebase warrants. A small CLI may only need
Level 1–2; a microservices system likely needs all three.

---

## Workflow

### Step 1: Check for existing documentation

Look for `ARCHITECTURE.md` in the project root and in `docs/`. If found, read it
fully before proceeding — preserve manually written sections when updating.

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
evidence found in Step 2 — note the file that evidences each one.

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

### Step 4: Write or update ARCHITECTURE.md

**Creating from scratch**: write the full template below.

**Updating existing file**:
- Update each `C4Context`, `C4Container`, `C4Component` code block to reflect current state
- Add new elements, remove elements that no longer exist
- Keep all manually maintained sections intact (anything after `## Design Decisions`,
  or sections marked `<!-- manually maintained -->`)
- Update the `Last updated:` date at the top

### Step 5: Report the changes

After writing the file, tell the user:
- Which diagrams were created or updated
- Architectural elements added or removed since last run
- Any gaps requiring manual input (unclear external dependencies, ambiguous relationships)

---

## ARCHITECTURE.md Template

```markdown
# Architecture

> Last updated: YYYY-MM-DD

## Table of Contents

- [System Context](#system-context)
- [Container Diagram](#container-diagram)
- [Component Diagrams](#component-diagrams)
- [Design Decisions](#design-decisions)

---

## System Context

[One paragraph describing the system purpose and its environment.]

```mermaid
C4Context
  ...
```

---

## Container Diagram

[One paragraph describing the major deployable units and how they fit together.]

```mermaid
C4Container
  ...
```

---

## Component Diagrams

### [Container Name]

[One paragraph describing this container's internal structure.]

```mermaid
C4Component
  ...
```

---

## Design Decisions

<!-- This section is manually maintained and will not be overwritten by /c4-docs. -->
<!-- Add Architecture Decision Records (ADRs) or key design notes here. -->
```

---

## Rules

- **Only document what exists** — every element and relationship must be evidenced
  by a specific file or code pattern found during analysis
- **Appropriate depth** — skip Level 3 for containers with trivial internals
- **Consistent naming** — use the same names as the codebase; do not rename things
- **Preserve manual sections** — `## Design Decisions` and any section marked
  `<!-- manually maintained -->` must never be overwritten
- **Accurate relationships** — only draw an arrow where there is code evidence
  of communication (import, HTTP call, DB connection, queue publish/consume)
- **Technology labels** — fill in the "Technology" field in Container/Component
  diagrams using the actual language, framework, or protocol found in the code
