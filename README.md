# `deploy/control-plane/` — staged artifacts for `excalibur-enterprise/proxy_control_plane` repo

This directory holds the **complete content** of the public
[`excalibur-enterprise/proxy_control_plane`](https://github.com/excalibur-enterprise/proxy_control_plane)
GitHub repository, staged in-tree so it lives under the same review +
test discipline as the proxy code that depends on it.

When the external repo is created (Phase 1.1), copy:

```
deploy/control-plane/pages/      → control-plane/pages/
deploy/control-plane/workflows/  → control-plane/.github/workflows/
deploy/control-plane/scripts/    → control-plane/scripts/
deploy/control-plane/README.md   → control-plane/README.md
```

Do NOT publish the operational private key — it lives in a GitHub
Encrypted Environment Secret named `OPS_PRIV_KEY_B64` (base64-std of
the raw 64-byte Ed25519 private key) on the `signing` environment.
The signing environment requires a manual reviewer for every job.

## Layout

| Path                                | Purpose                                                                                                                                |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `pages/index.html`                  | Marketing front page, served at <https://excalibur.dev>.                                                                               |
| `pages/landing.html`                | Marketplace post-purchase landing page. Reads `?token=…` from the URL and `repository_dispatch`es the GH Actions fulfillment workflow. |
| `pages/license-format.md`           | Mirror of [`docs/license-format.md`](../../docs/license-format.md) so customers can verify the wire format independently.              |
| `pages/public-key.pem`              | PKIX SPKI PEM of the embedded root pubkey. Identical to the output of `excalibur-ctl license keys export`.                             |
| `pages/signing-keys/operational-cert.json` | Currently active operational cert (root-signed). Rotated quarterly.                                                             |
| `workflows/azure-fulfill.yml`       | `repository_dispatch:azure-fulfill` → resolve marketplace token, activate, sign license bundle, commit to `bundles/<id>.json`.         |
| `workflows/marketplace-poll.yml`    | `*/5 * * * *` cron — diffs `GET /subscriptions` against the committed entitlements list and reissues / suspends as needed.             |
| `workflows/aws-fulfill.yml`         | `repository_dispatch:aws-fulfill` → GitHub-OIDC into AWS, resolve entitlement, sign bundle, commit to `entitlements/aws/<id>.json`.    |
| `workflows/aws-marketplace-poll.yml`| `*/5 * * * *` cron — walks `entitlements/aws/`, probes each customer via `GetEntitlements`, suspends on rc=3, reissues within 7d.      |
| `workflows/release-pages.yml`       | Publishes `pages/` to `gh-pages` on every push to `main`.                                                                              |
| `scripts/refresh-public-key.sh`     | Regenerates `pages/public-key.pem` from the embedded constant in `internal/license/keys.go`.                                           |

## Branch protection (configure in repo settings)

- `main` requires:
  - Pull-request review by a CODEOWNER
  - Signed commits
  - Status checks: `release-pages`
- The `signing` environment requires:
  - Manual reviewer approval for every deployment
  - Restricted to `main`
- **Forbid `pull_request_target` triggers** anywhere in `.github/workflows/` —
  every signing workflow MUST run only on `repository_dispatch` or
  `workflow_dispatch` from a maintainer.
