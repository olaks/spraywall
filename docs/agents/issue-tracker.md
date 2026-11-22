# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files in `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file
- Triage state is recorded as a `Status:` line near the top of each issue file (see `triage-labels.md` for the role strings)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`, and a `Claimed by:` line records who holds a claimed ticket.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are open, unblocked, and unclaimed (no `Status: claimed`, no `Claimed by:`); first by number wins.
- **Claim**: before any work, set `Status: claimed` and add a `Claimed by: <session name> <ISO time>` line just below it (session name = your name in `ListAgents`, or a short name you'll keep for the session), then save. Then **read the file back**: if the `Claimed by:` line isn't yours, another session won the race, so leave the ticket alone and pick the next one. A `claimed` ticket without a `Claimed by:` line comes from before this rule; ask the user before taking it.
- **Release**: when giving a ticket up unresolved, set `Status: open` and delete the `Claimed by:` line. On resolve, keep the line as a record of who resolved it.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.

## Repo-specific notes

- This repo is not a git repository yet, so research findings can't go on a `research/<name>` branch. They go in `.scratch/<effort>/research/<slug>.md` instead, linked from the ticket.
- Answers and resolution comments go under `## Answer` in the ticket file.
