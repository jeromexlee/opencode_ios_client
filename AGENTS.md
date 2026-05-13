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

## Local Notes

- `xcodebuild build` and `xcodebuild test` must run sequentially, not in parallel, because this repo shares the same DerivedData/build database and concurrent runs commonly fail with `build.db: database is locked`.
- If you need both validations, run build first, wait for it to finish, then run tests.
- Keep chat input UI tests anchored on stable accessibility identifiers rather than `TextField`-specific queries, because the composer implementation may use UIKit bridges.
- When the user is actively using an existing OpenCode server, do not kill or restart the live process, especially anything bound to port `4096`.
- In that situation, skip destructive runtime validation against the live server; if runtime verification is still needed, use a separate temporary port/process and never touch the user's active `4096` process.
