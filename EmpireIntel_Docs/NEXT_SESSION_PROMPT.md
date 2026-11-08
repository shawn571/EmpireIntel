You are continuing the EmpireIntel project (GitHub: shawn571/EmpireIntel, private). The newest docs are on `main`; if the newest section of Session_Handoff.md names a different branch, use that one.

1. Fetch the repository and check out the branch named above.
2. Read EmpireIntel_Docs/CODE_STANDING_ORDERS.md, then the newest section of EmpireIntel_Docs/Session_Handoff.md, then EmpireIntel_Docs/Project_Bible.md.
3. Verify them against the repository: branches and their heads, versions in each addon's TOC, what main holds, and that tests pass (lua5.1 Tests/run.lua and lua5.3 Tests/run.lua).
4. Report, briefly: what you verified, any conflict between the docs and the repository, and the open questions and next step from the handoff. End with the standing orders' report format.
5. Wait for my approval before changing any code, merging anything or starting any increment.

Merging (D-049): “Once I approve a merge in chat, you merge it yourself through its pull request (gh pr merge <n> --merge; no squash, no rebase, no direct push to main), then check main and report the merge commit and the test result. Approval is still required for every merge except the docs-only standing approval. Commits and pushes to work branches need no approval. Never force-push or delete branches.”
Merge command (D-050): “Use the REST merge command (gh api -X PUT repos/shawn571/EmpireIntel/pulls/<n>/merge -f merge_method=merge) in place of gh pr merge: approved.”
Docs-only standing approval (D-049): “you may merge docs-only pull requests that change only Session_Handoff.md, NEXT_SESSION_PROMPT.md, CODE_STANDING_ORDERS.md or the recording of my decisions; tell me each time.”
