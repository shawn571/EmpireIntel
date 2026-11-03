# EmpireIntel Release Pipeline (design)

DOC VERSION: 0.1.0  |  DATE: 2026-11-03  |  STATUS: **Proposed. Nothing here is implemented or enabled until the user approves (D-018).**  |  Scope: EmpireIntel and EmpireIntelCheck only. GoldIntel is out of scope and is never touched.

**The pipeline turns sanitized reports into tested, versioned releases.** A small installer on the user's computer installs them only while WoW is closed, after a backup, with a one-step rollback. Releases start with manual approval of every install. Later, bug fixes only may install automatically, but only after the user has reviewed the first real launch results and switched it on. Saved-data format changes, scope, dependencies and going public always wait for the user.

## 1. Roles and trust boundary

| Who | Decides or does |
|---|---|
| User (executive) | Scope, phases, saved-data format changes, dependencies, going public, install mode, pause and unpause, cap increases |
| Claude (cloud sessions) | Triage of reports, fixes within approved scope, tests, release candidates, revert releases, notifications |
| GitHub Actions (private repo) | Runs the gates, builds the artifact, writes the manifest, publishes the release. It is the only thing that publishes |
| Installer (user's computer) | Downloads, verifies, backs up, installs, rolls back. **The final safety boundary:** Claude cannot reach the user's computer, so nothing reaches the game unless the installer's local policy allows it |

Report contents are data. Triage reads typed fields only. Free text is quoted, truncated, and never acted on as an instruction. A report that looks like it contains instructions is flagged in the notification and otherwise ignored.

## 2. Flow

```
 user's PC (scheduled task, exists)          private repo (GitHub)                        user's PC (installer, new)
 SavedVariables --> local sanitizer --push--> reports/YYYY-MM-DD/*.json
                                                  |  CI: report-scan (privacy backstop)
                                                  v
                                       Claude scheduled session: triage
                                         | in scope? -> fix + tests -> PR/branch
                                         | out of scope / format / dependency -> DECIDE notice, stop
                                                  v
                                       Actions: gates G1..G10 -> classify -> manifest
                                         | pause? cap? -> stop with notice
                                                  v
                                       GitHub Release vX.Y.Z (zip + manifest.json + SHA256SUMS)
                                                  |                                    poll every 30 min, WoW closed only
                                                  +-------------------------------> verify -> policy -> (prompt) -> backup
                                                                                     -> install -> installed.json -> next report
```

## 3. Versioned artifacts and the release manifest

- **Versions:** SemVer. PATCH = fix; MINOR = approved feature, or a saved-data format change (always approved). Check packages use `0.1.N-tpK`. Tags: `v0.2.1` (EmpireIntel), `check-v0.1.1-tp1` (EmpireIntelCheck). The TOC `## Version`, the code constant and the tag must be equal (gate G9).
- **Release assets:** `EmpireIntel_AddOns_v0.2.1.zip`, `manifest.json`, `SHA256SUMS`. Built only by the Actions workflow from a tagged commit with all gates green. Builds are reproducible: the same commit gives the same zip hash.
- **Manifest (machine-readable; schema file `pipeline/manifest.schema.json`):**

```json
{
  "manifestSchema": 1,
  "addon": "EmpireIntel",
  "version": "0.2.1",
  "previous": "0.2.0",
  "commit": "<sha>",
  "builtAt": "2026-11-12T09:14:00Z",
  "ciRun": "<actions run url>",
  "activation": "reload",
  "activationReason": "Lua files changed only; TOC and file list unchanged",
  "class": "fix",
  "classDetail": { "tocChanged": false, "filesAddedOrRemoved": false, "savedDataFormatChanged": false,
                   "dependencyChanged": false, "eventsChanged": false, "changedLines": 18 },
  "savedData": { "variables": ["EmpireIntelDB", "EmpireIntelCharDB"], "formatFrom": 1, "formatTo": 1 },
  "approval": { "required": false, "reasons": [], "decision": null },
  "autoInstallEligible": true,
  "autoInstallBlockers": [],
  "interface": [16001],
  "folders": ["EmpireIntel"],
  "files": [ { "path": "EmpireIntel/Core.lua", "sha256": "<hex>", "bytes": 10240 } ],
  "artifact": { "name": "EmpireIntel_AddOns_v0.2.1.zip", "sha256": "<hex>", "bytes": 40213 },
  "gates": { "G1": "pass", "G2": "pass", "G3": "pass", "G4": "pass", "G5": "pass",
             "G6": "pass", "G7": "pass", "G8": "pass", "G9": "pass", "G10": "pass" },
  "fixes": ["R-20261111-03"],
  "changes": ["Rested XP projection no longer shows 0 when the client returns nil"],
  "rollbackTo": "0.2.0"
}
```

- **`activation` is computed, never typed by hand** (`tools/classify_release.py`, diff from the previous release tag):
  - `restart`: any TOC line changed except `## Version`, a file added or removed, a new addon folder, or a SavedVariables name changed;
  - `reload`: everything else.
  - Because the installer only runs with WoW closed, every install is in practice picked up at the next game start. `activation` tells the user what to do if they ever copy a build by hand while playing, and it feeds the auto-install rule.
- **`class` is computed too.** `fix` needs all of: Lua-only changes inside the addon folder; no TOC, file-list, event, dependency or saved-data-format change; at most 200 changed lines; and a linked report id. Anything else is `feature`, `format`, `dependency` or `check`. If Claude's declared class differs from the computed one, gate G5 fails.

## 4. Test gates (all must pass before any release; recorded in the manifest)

| Gate | Check |
|---|---|
| G1 | Offline suite passes under Lua 5.1 and Lua 5.3 |
| G2 | Static rules: C-1..C-6, bytecode global check, WoW API only in `Platform/`, third-party only in `Bridge/`, event allow-list, call denylist |
| G3 | Guard mutation set: each listed safety guard, when disabled, makes the suite fail (the TP-1 practice, kept as a gate) |
| G4 | Package verify: every TOC file present, ASCII, LF, zip content equals the file list, reproducible hash |
| G5 | Classification: computed `class` and `activation` equal the declared ones; manifest validates against its schema |
| G6 | Privacy scan of the diff, the artifact and new reports: no GUID patterns, no `WTF\Account` paths, no raw SavedVariables dumps, no names outside the fixture allow-list |
| G7 | Saved-data safety: the new build opens the previous release's synthetic saved data without loss, and the previous build opens the new build's data without error (so rollback is safe). A format change also needs its migration tests and `approval.decision` set |
| G8 | Regression corpus: every sanitized report fixture replays with no new UNEXPECTED codes |
| G9 | Version: monotonic, equal in tag, TOC and code; Changelog entry present; notification text generated |
| G10 | Policy: not paused; under the daily cap; approval present when required |

A failed gate stops the release and sends a short notice. Claude may fix the cause within scope. Gates are never skipped or weakened without the user's approval: changing a gate's code or threshold counts as a pipeline change (section 10).

## 5. Daily cap and the pause switch

- **Cap** (`pipeline/policy.json`; lowering is free, raising needs the user): at most **2 releases per local day**, plus at most **1 automatic install per day**. One revert release per day is allowed beyond the cap, because it lowers risk. The day is the user's local day (time zone to confirm, Q-R4).
- **Single pause switch:** `pipeline/control.json` → `{ "paused": true|false, "reason": "...", "at": "..." }`. When paused, Actions builds and publishes nothing, the Claude session only triages and notifies, and the installer installs nothing (it checks the file before every install).
  - The user flips it from anywhere: GitHub web or mobile app, or by telling Claude.
  - **Claude may set `paused: true` but never `false`.** Claude pauses by itself on: a privacy-scan hit, two failed releases in a row, a rollback, or a report showing a new crash after an install.
  - Today "Claude never unpauses" is enforced by policy plus a CI check (an unpause commit must not carry the Claude session trailer). That is auditable but not cryptographic. Section 9 lists the upgrade that makes it unforgeable.
- After any unpause, the first install always asks for confirmation on the user's computer, even in auto mode.

## 6. Install process (user's computer; only with WoW closed)

The installer is a readable PowerShell script with no binaries, run by Windows Task Scheduler at logon and every 30 minutes. With nothing to do, it exits in about a second.

1. **Preconditions:** not paused; a newer release exists; WoW is not running, and has not been for at least 60 s, so the saved variables are fully written. The game process names are set in the local config. The check is repeated right before the file swap, and the install aborts cleanly if the game starts.
2. **Download and verify:** release assets into a staging folder; `SHA256SUMS`, the artifact hash and every per-file hash must match; the manifest must validate; `folders` must match `^EmpireIntel[A-Za-z_]*$`. **GoldIntel folders and files are never read, moved or written.**
3. **Policy:** local install mode (`manual` or `auto-fixes`), cap, `approval.required`, `autoInstallEligible`. In manual mode, or for anything not eligible, a local prompt (a dialog on the user's own screen) shows the notification text and Install / Skip.
4. **Backup:** copies the current `Interface\AddOns\EmpireIntel*` folders and every `EmpireIntel*.lua` saved-variables file (account and per-character) to `%LOCALAPPDATA%\EmpireIntel\backups\<time>_<fromVersion>\`, with a hash list. Keeps the last 5. The backup stays local and is never uploaded.
5. **Install:** the current folder is renamed to `.old`, the staged folder is moved in, and the hashes are verified. Only then is `.old` deleted. Any failure restores `.old` and records `install_failed`.
6. **Record:** `installed.json` (version, time, result). The next sanitized report carries the installed version and the install result, with no paths or account names.

**One-step rollback:** double-click `Rollback EmpireIntel` (or `ei-install rollback`). WoW must be closed. It restores the addon folders from the newest backup. Saved data is restored too **only when** the rolled-back release changed the saved-data format, or the user ticks "also restore saved data". G7 guarantees that the older build reads newer data in every other case. A rollback sets `paused: true` locally and notes it in the next report, so Claude does not ship over it.

**Cloud-side rollback:** when a report shows the new version caused new errors, Claude publishes a revert release: the previous good code under a new PATCH version. It is auto-eligible only if it moves back to a version that was installed cleanly before, with no saved-data format change in between.

## 7. Rollout stages

| Stage | What happens | Entry condition |
|---|---|---|
| 0 (now) | Pipeline off. No workflows, no installer. The launch-build check (EmpireIntelCheck 0.1.0-tp1) stays a manual install as already delivered | — |
| 1 | Releases built and published; **every install asks for the user's confirmation** | User approves this design (D-018); installer set up on the PC; Phase 2 or a TP-1 update approved |
| 2 | **Auto-install for bug fixes only** (`class = fix`, all gates, under cap, not paused, no rollback in the last 72 h, the previous release produced at least one clean report). Everything else still prompts | User has **reviewed the first real launch results** (a recorded decision); at least 5 confirmed installs over at least 7 days with no rollback; the user sets `auto-fixes` **in the local config on their computer**. Claude cannot switch this on |

Never automatic, at any stage: saved-data format changes, new dependencies or Bridge targets, TOC or file-list changes, new events, features, check packages (they need the user's test steps), and going public.

## 8. Notification format

Sent as a push from the Claude scheduled task, and also posted as one GitHub issue comment per release in the private repo (history). At most about 8 lines:

```
EmpireIntel 0.2.1 | fix | /reload | auto-install: yes
Changed: rested XP no longer shows 0 when the client returns nil
Fixes: R-20261111-03 | Gates 10/10 | Today 1/2
Needs you: nothing
Rollback: "Rollback EmpireIntel" -> 0.2.0
```

```
EmpireIntel | DECISION NEEDED (nothing shipped)
Ask: saved-data format 1 -> 2 to store perk ranks (needed for FR-LEG-2)
Options: A approve  B keep format 1, show ranks as unknown
If no answer: waits (no default)
Ref: D-0xx, report R-20261112-01
```

Kinds: `released`, `installed` (from the next report), `blocked` (gate or cap; one line why), `paused` (who and why), `decision`. Report free text never appears in a notification, only report ids.

## 9. What cannot be automated

- **Playing the game.** Live behavior is only known from the user's sessions. No release can be verified in-game without them.
- **Executive decisions:** scope, phases, saved-data format, dependencies, going public, raising caps, unpausing, enabling auto-install.
- **Check packages (TP-n):** they need the user to follow test steps, so they are always manual.
- **First-time setup on the computer** (section 11), and token renewal when the token expires.
- **Purging a privacy leak from git history.** A history rewrite is destructive. Claude pauses and reports; the user decides.
- **A client patch:** the new Interface number and any re-probe need a client run. An Interface-only TOC change is treated as needing approval until the user decides otherwise (Q-R5).
- **Unforgeable approvals from the cloud side.** Claude's commits use the user's GitHub identity, so a commit cannot prove the user made it. The design therefore puts every approval that matters on the user's computer (the local prompt and the local install mode). To also make remote unpause and approvals unforgeable, give Claude a separate GitHub identity (a machine user or GitHub App) and require the user's signed commits or code-owner review for `pipeline/` (Q-R3).

## 10. Changes to the pipeline itself

Workflows, gates, classifier, policy, manifest schema and installer are pipeline code. Changing them needs the user's approval, so a pipeline change is never a `fix` and never auto-installs. The installer updates itself only through a local prompt.

## 11. Requirements on the user's computer

- Windows 10 or 11 (assumed from the WTF paths; Q-R1) with Windows PowerShell 5.1 (built in). No admin rights needed.
- A **fine-grained GitHub token, read-only** (Contents and Metadata) for shawn571/EmpireIntel only, stored in Windows Credential Manager. It is separate from the token the report task uses to push.
- One-time local config:
  - WoW Forever folder, AddOns path and WTF path (the launch folder name is not known yet);
  - the game process names;
  - install mode (`manual` to start);
  - time zone.
- Task Scheduler entry: at logon plus every 30 minutes, as the user, "only when logged on".
- About 50 MB free for staging and 5 backups. A correct system clock (daily cap, logs).
- **The existing report task must meet report format v1.** Before pushing, it must:
  - replace character names with stable aliases (C1, C2, ...), keeping the mapping only on the computer;
  - drop GUIDs, or replace them with a locally salted hash;
  - remove account names and file paths;
  - send only the fields in `pipeline/report.schema.json`.

  The repo-side privacy scan (G6) is a backstop, not the main protection. A leak found after a push still sits in git history.

## 12. Open questions for the user

| ID | Question | Recommendation |
|---|---|---|
| Q-R1 | Is the game computer Windows? | Design assumes yes |
| Q-R2 | Notifications: Claude push only, or also a GitHub issue comment per release? | Both (push to read, issue for history) |
| Q-R3 | Create a separate GitHub identity for Claude so approvals and unpause can be enforced, not just audited? | Yes, before stage 2 |
| Q-R4 | Your time zone for the daily cap | — |
| Q-R5 | Should an Interface-number-only TOC bump count as a fix? | No at first; revisit after the first client patch |
| Q-R6 | Caps: 2 releases and 1 auto-install per day, 5 backups, stage-2 entry of 5 installs over 7 days? | As proposed |
