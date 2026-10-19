# Runbook — repository and login-item settings after the security review

Created: 2026-10-18 19:12 -05:00 · Edited: 2026-10-18 19:12 -05:00

For the owner. Closes O17 and O18 from `docs/reviews/security-2026-10-18.md`. Every step is a setting only the repository owner or the Mac's user can change; the agent cannot make them and does not try. Each step has a browser path and, where GitHub offers one, a terminal command you can run with the `!` prefix in this session. Each step ends with how to see that it took.

Already in place, nothing to do: secret scanning and push protection are **enabled** on the repository (public repositories get them by default). Confirmed 2026-10-18 by `gh api repos/martin-gleason/dockwatch --jq .security_and_analysis`.

## 1. The ruleset: a pull request and a green CI run before anything lands on main

Today the "Rebase-n-Merge" ruleset only blocks deleting `main` and force-pushing to it. It does not require a pull request, a passing check, or a rebase merge, which is why PR #8 could land as a merge commit.

**Browser.** GitHub → the repository → **Settings** → **Rules** → **Rulesets** → **Rebase-n-Merge** → under *Branch rules* tick:

- **Require a pull request before merging.** Required approvals: 0 (you are the only reviewer, and you review by merging). Under *Allowed merge methods*, leave only **Rebase** ticked.
- **Require status checks to pass.** Tick *Require branches to be up to date before merging*. Click *Add checks*, search `test`, pick the one whose source is **GitHub Actions** (that is the `test` job in `.github/workflows/ci.yml`).
- Leave *Restrict deletions* and *Block force pushes* ticked as they are.
- *Bypass list* stays empty. That includes you: a direct `git push origin main` from your own machine will be refused from now on, which is the point.

**Save changes** at the bottom.

**Terminal, same result in one call.** This replaces the ruleset's rules wholesale with the four above:

```sh
gh api -X PUT repos/martin-gleason/dockwatch/rulesets/25349652 --input - <<'JSON'
{
  "name": "Rebase-n-Merge",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [],
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request",
      "parameters": { "required_approving_review_count": 0,
                      "dismiss_stale_reviews_on_push": false,
                      "require_code_owner_review": false,
                      "require_last_push_approval": false,
                      "required_review_thread_resolution": false,
                      "allowed_merge_methods": ["rebase"] } },
    { "type": "required_status_checks",
      "parameters": { "strict_required_status_checks_policy": true,
                      "required_status_checks": [ { "context": "test" } ] } }
  ]
}
JSON
```

**Check it took.**

```sh
gh api repos/martin-gleason/dockwatch/rulesets/25349652 --jq '.rules[].type'
```

should print `deletion`, `non_fast_forward`, `pull_request`, `required_status_checks`. The next pull request's page will show "Required: test" under the checks, and the merge button will offer rebase only.

## 2. Actions: approve every outside fork before its workflow runs

Today a fork pull request from anyone who has contributed once runs CI without approval. CI has a read-only token and no secrets, so what is at stake is compute and the habit; set it to approval for all outside collaborators.

**Browser.** **Settings** → **Actions** → **General** → *Fork pull request workflows from outside collaborators* → choose **Require approval for all external contributors** → **Save**.

**Terminal.**

```sh
gh api -X PUT repos/martin-gleason/dockwatch/actions/permissions/fork-pr-contributor-approval \
  -f approval_policy=all_external_contributors
```

**Check it took.**

```sh
gh api repos/martin-gleason/dockwatch/actions/permissions/fork-pr-contributor-approval
```

should print `"approval_policy":"all_external_contributors"`.

## 3. Optional: secret scanning for non-provider patterns

Push protection already blocks known provider tokens (GitHub, AWS, Slack, Anthropic and the like). Non-provider patterns (generic "password =", private-key headers) are off; turning them on costs nothing on a repository this size.

**Browser.** **Settings** → **Code security** → *Secret scanning* → **Non-provider patterns** → **Enable**.

**Terminal.**

```sh
gh api -X PATCH repos/martin-gleason/dockwatch \
  --input - <<'JSON'
{ "security_and_analysis": { "secret_scanning_non_provider_patterns": { "status": "enabled" } } }
JSON
```

**Check it took.** `gh api repos/martin-gleason/dockwatch --jq .security_and_analysis.secret_scanning_non_provider_patterns.status` prints `enabled`.

## 4. The login item on this Mac (O17)

Background Task Management records DockWatch's login item as enabled at `~/Applications/DockWatch.app`, while launchd shows no job for it. The setting should be **off** until the app is signed with a Developer ID (D30), because an ad-hoc-signed bundle in a user-writable folder is a persistence slot anyone running as you could take over.

**Steps.** Apple menu → **System Settings** → **General** → **Login Items & Extensions**. Under *Open at Login*, look for **DockWatch**.

- If it is listed: select it and click **–** (minus) to remove it. Then open DockWatch's menu and make sure **Launch at Login** shows unticked.
- If it is not listed: nothing to do; tell me, and O17 closes with "not registered".

**Check it took.** In a terminal:

```sh
sfltool dumpbtm | grep -A9 "Name: DockWatch" | grep Disposition
```

An entry that is gone or reads `[disabled, …]` is what you want.

## 5. Tell the agent

Reply with which steps you did. O17 and O18 close with the output of the "check it took" lines pasted into the register, not with "done".
