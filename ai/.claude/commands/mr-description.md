---
description: Generate a GitLab merge request description for the current branch
---

Generate a comprehensive GitLab merge request (MR) description for a branch by analyzing the changes compared to the base branch.

**Usage:**
- `/mr-description` - Generate MR description for the current branch
- `/mr-description <branch-name>` - Generate MR description for the specified branch

Instructions:
1. Parse the command arguments:
   - If an argument is provided, use it as the target branch
   - If no argument is provided, use the current branch (get with `git branch --show-current`)
2. Determine the base branch (prefer FLS1250-SNMP, develop, then main, then master)
3. Get the diff statistics: `git diff <base-branch>...<target-branch> --stat`
4. Get the commit history: `git log <base-branch>..<target-branch> --oneline`
5. Analyze the full diff to understand the changes: `git diff <base-branch>...<target-branch>`
5. Generate an MR description that includes:
   - **Summary**: High-level overview of what this MR accomplishes
   - **Key Changes**: Organized list of major changes by category/module
   - **Files Changed**: Statistics (files changed, insertions, deletions)
   - **Configuration**: Any new configuration options or changes (use ```ini or ```c code blocks)
   - **Performance Impact**: Notable performance improvements or considerations
   - **Testing**: Description of test coverage for new features
   - **Migration Notes**: Any breaking changes or migration guidance
   - **Additional Context**: Relevant background information

Format the description in GitLab-flavored Markdown with appropriate headers, lists, and code blocks (use ``` with language identifier, e.g., ```ini, ```c, ```bash).

Focus on changes that matter to reviewers - highlight new functionality, refactorings, bug fixes, and architectural improvements. Include specific line references for important changes when relevant.

After generating the description, save it to a temporary file and copy it to the clipboard using:
```bash
echo "<description>" | xclip -selection clipboard
```
or on macOS:
```bash
echo "<description>" | pbcopy
```

Then inform the user that the description has been copied to their clipboard and is ready to paste into GitLab.
