---
name: prd-to-jira
description: |-
  Reads a PRD from a Confluence page and creates Jira tickets from it:
  one Epic for the feature and one Story per requirement row in the
  Requirements table. Links each Story to the Epic.
  Trigger when user says: "create jira tickets from PRD", "turn PRD into tickets",
  "generate jira issues from confluence PRD", "/prd-to-jira", or asks to
  create tickets/issues from a PRD or Confluence page.
---

You are creating Jira tickets from a PRD stored in Confluence. Follow the steps below precisely.

**Host and connector independence:** Use the current host's equivalent interaction and Atlassian connector capabilities. Names such as `getConfluencePage` and `createJiraIssue` describe required service operations, not required host-specific tool names.

## Step 1: Get the Confluence page

If the user provided a Confluence URL or page ID in their message, extract the page ID from it:
- Tiny link format: `/wiki/x/<ID>` — use `<ID>` directly as `pageId`
- Long format: `/wiki/spaces/<SPACE>/pages/<ID>/...` — use the numeric `<ID>`
- If no page was provided, use the host's user-interaction mechanism to ask for the Confluence page URL or page ID.

## Step 2: Resolve cloud ID

Call `getAccessibleAtlassianResources` to get the Confluence/Jira cloud ID. Use the first result's `id` field as `cloudId` for all subsequent calls.

## Step 3: Fetch the PRD

Call `getConfluencePage` with:
- `cloudId` — from Step 2
- `pageId` — from Step 1
- `contentFormat` — `"markdown"`

## Step 4: Parse the PRD

Extract the following from the page content:

- **Feature name** — the top-level `# heading`
- **Objective** — the text under the `## Objective` section
- **Requirements** — every data row in the `## Requirements` table. For each row capture:
  - Requirement name (column 1)
  - User story (column 2)
  - Importance (column 3): Must / Should / Could / Won't
  - Jira Issue key if already filled (column 4) — skip creating a ticket for this row if a key is present
  - Notes (column 5)

If the Requirements table is missing or empty, tell the user and stop.

## Step 5: Confirm Jira project

Use the host's user-interaction mechanism to ask:
1. Which Jira project should the tickets be created in? (project key, e.g. `MYAPP`)
2. Should tickets for "Won't" requirements be skipped? (default: yes)

## Step 6: Resolve issue types

Call `getJiraProjectIssueTypesMetadata` with the `cloudId` and `projectKey` to retrieve available issue types.

- Find the issue type named **Epic** (or closest match). Note its name exactly.
- Find the issue type to use for requirements — prefer **Story**, fall back to **Task**. Note its name exactly.
- Determine project style:
  - **Next-gen / team-managed**: Epic is a standard issue type and child issues use the `parent` field to link to an Epic.
  - **Classic / company-managed**: Stories link to Epics via `additional_fields: {"customfield_10014": "<EPIC-KEY>"}`.
  - Detect by checking if the issue types include a `Subtask` type with a `subtask: true` flag — classic projects have this. If unsure, assume next-gen.

## Step 7: Create the Epic

Call `createJiraIssue` with:
- `cloudId`
- `projectKey`
- `issueTypeName` — the Epic type name from Step 6
- `summary` — the feature name from the PRD
- `description` — the Objective text from the PRD
- `contentFormat` — `"markdown"`

Record the returned issue key (e.g. `MYAPP-1`) as `epicKey`.

## Step 8: Create one Story per requirement

For each requirement row (skipping any with an existing Jira key, and skipping "Won't" rows if the user chose to):

Call `createJiraIssue` with:
- `cloudId`
- `projectKey`
- `issueTypeName` — Story (or Task) from Step 6
- `summary` — the requirement name
- `description` — formatted as:

  ```
  **User Story**
  [user story text]

  **Importance:** [Must / Should / Could / Won't]

  **Notes:** [notes or —]
  ```

- `contentFormat` — `"markdown"`
- Link to the epic:
  - Next-gen: `parent` — `epicKey`
  - Classic: `additional_fields` — `{"customfield_10014": "<epicKey>"}`

Collect each created issue key.

## Step 9: Report results

Output a summary table:

| Requirement | Jira Issue | Importance |
|-------------|------------|------------|
| [name] | [KEY-123](link) | Must |
| … | … | … |

Then show the Epic: **[FEATURE-NAME](link) — [epicKey]**

If any issue creation failed, list the failures and offer to retry them.

## Step 10: Offer to update the Confluence PRD

Ask the user: "Would you like me to update the Jira Issue column in the Confluence PRD with the new ticket keys?"

If yes, fetch the current page version, replace each empty Jira Issue cell in the Requirements table with the corresponding ticket key as a Confluence smart link (`<a href="[JIRA_URL]/browse/[KEY]" data-card-appearance="inline">[KEY]</a>`), and call `updateConfluencePage` with the updated HTML body.
