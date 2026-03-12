# Repository Instructions

## Fork Workflow

This repository is a fork of `grapeot/opencode_ios_client`.

- `origin`: `git@github.com:jeromexlee/opencode_ios_client.git`
- `upstream`: `git@github.com:grapeot/opencode_ios_client.git`
- Product branch: `master`
- Upstream tracking branch: `upstream-main` tracking `upstream/master`

## Branch Policy

- Keep user/custom product work on `master`
- Never do custom development on `upstream-main`
- Treat `upstream-main` as a local mirror of upstream only
- Prefer `merge` for bringing upstream changes into `master`
- Do not routinely `rebase` `master` onto upstream

## Sync Procedure

When syncing upstream changes, use this flow:

```bash
git fetch upstream
git switch upstream-main
git merge --ff-only upstream/master
git switch master
git merge upstream-main
```

## Working Tree Safety

- Before switching branches, check for uncommitted changes
- If the working tree is dirty, commit or stash before `git switch`
- Do not discard user changes unless explicitly requested
- Do not rewrite history on `master` unless explicitly requested

## Agent Default

When the user asks to keep the fork updated, perform the upstream sync workflow above by default.
