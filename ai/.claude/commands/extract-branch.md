# Extract Branch

Help me extract the current changes into a new feature branch while preserving my work-in-progress state.

Follow these steps:

1. Show me the current git status and branch information
2. Ask me for:
   - A descriptive branch name for the new feature (suggest one based on the changes if possible)
   - Which files/changes should go to the new branch (default: all unstaged changes)
3. Create and switch to the new feature branch from the main branch (develop)
4. Apply the selected changes to the new branch
5. Commit the changes with an appropriate commit message
6. Switch back to the original branch
7. Restore any remaining work-in-progress state

Handle all scenarios:
- Extracting unstaged changes (using git stash)
- Extracting staged changes (using git reset and stash)
- Extracting existing commits (using cherry-pick and rebase)

For extracting commits:
- First, use `git log --oneline <base-branch>..HEAD` (e.g., `git log --oneline develop..HEAD`) to show commits that exist on the current branch but not on the base branch
- Look at the commit history since diverging from the base branch to identify the relevant commit(s) to extract
- Ask which commit(s) to extract based on the commit message or files modified
- Create a new branch from the base branch (develop)
- Cherry-pick the selected commit(s) to the new branch
- Remove the commit(s) from the original branch using `git rebase --onto <commit-before>~ <commit> HEAD`

Make sure to preserve any work that should stay on the original branch.