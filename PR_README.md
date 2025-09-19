# PrepperPi Baseline Polish PR Bundle

This bundle contains ready-to-commit files to improve project hygiene, security defaults, and CI.

## Files included
- .github/workflows/ci.yml — CI with ruff/black/pytest/shellcheck
- .github/dependabot.yml — weekly dependency updates
- CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md
- .gitignore — ignores data/, logs/, backup/, env files
- config/*.example — sample configs to copy and edit
- manifests/standard.txt — example ZIM set manifest
- scripts/install.sh, scripts/uninstall.sh — idempotent helpers
- scripts/healthcheck.sh — basic service/disk health
- systemd/kiwix-serve.service.d/override.conf — hardening

## How to use in your repo
1. Extract into your repo root (`/opt/prepperpi`).
2. Create a branch:
   git checkout -b chore/baseline-polish
3. Add & commit:
   git add .
   git commit -m "chore: baseline polish (CI, dependabot, examples, hardening)"
4. Push & open PR:
   git push origin chore/baseline-polish
   # then open the PR on GitHub comparing this branch into main
