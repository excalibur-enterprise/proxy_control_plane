# Excalibur Proxy — Control Plane

Public, auditable control plane for [Excalibur Proxy](https://excalibur.dev).

This repository hosts:

- **The marketing and post-purchase pages** served at <https://excalibur.dev> (in [`pages/`](pages/)).
- **The marketplace fulfillment workflows** that activate AWS and Azure subscriptions, sign per-customer license bundles with our offline operational key, and publish them as static JSON (in [`.github/workflows/`](.github/workflows/)).
- **The current public verification key** customers and auditors can pin to verify any license bundle Excalibur has ever issued (in [`pages/public-key.pem`](pages/public-key.pem) once published).

Everything in this repo is intentionally public so that customers can verify, byte-for-byte, what is being signed on their behalf and which key is signing it.

## Why this exists

Excalibur Proxy is self-hosted: every byte of customer traffic stays in the customer's own AWS account. The only thing the proxy ever fetches from us is a small, signed **license bundle** that confirms the customer's entitlement (plan tier, workload limits, expiry).

Rather than run a closed-source license server, we run the entire issuance path in this public repo:

1. Customer subscribes on AWS or Azure Marketplace.
2. Marketplace redirects them to a static page in [`pages/`](pages/).
3. That page hands the marketplace token to a GitHub Actions workflow in this repo via `repository_dispatch`.
4. The workflow calls the marketplace's own resolution API to confirm the purchase.
5. It signs a license bundle with the offline operational key and commits the bundle to this repo.
6. The customer's proxy fetches the bundle from `https://excalibur.dev/...` on its normal refresh cycle.

Every signing run is a public Actions log. Every issued bundle is a public commit. Every key rotation is a public commit. There is no hidden state.

## Verifying a license bundle

```bash
excalibur-ctl license verify ./bundle.json
```

The CLI ships an embedded copy of the long-lived root public key. The root signs short-lived **operational certificates**, and operational certs sign individual customer bundles. The current operational cert is published at [`pages/signing-keys/`](pages/signing-keys/) and rotated quarterly.

Wire format and signature scheme: [`pages/license-format.md`](pages/license-format.md).

## Layout

| Path                                           | Purpose                                                            |
| ---------------------------------------------- | ------------------------------------------------------------------ |
| `pages/index.html`                             | Marketing front page served at <https://excalibur.dev>.            |
| `pages/landing.html`                           | Marketplace post-purchase landing page.                            |
| `pages/license-format.md`                      | License bundle wire format.                                        |
| `pages/public-key.pem`                         | Long-lived root verification key (PKIX SPKI PEM).                  |
| `pages/signing-keys/`                          | Active operational certificate(s).                                 |
| `.github/workflows/aws-fulfill.yml`            | AWS Marketplace SaaS fulfillment.                                  |
| `.github/workflows/azure-fulfill.yml`          | Azure Marketplace SaaS fulfillment.                                |
| `.github/workflows/aws-marketplace-poll.yml`   | AWS entitlement reconciliation (suspend / reissue).                |
| `.github/workflows/marketplace-poll.yml`       | Azure entitlement reconciliation.                                  |
| `.github/workflows/release-pages.yml`          | Publishes `pages/` to GitHub Pages.                                |
| `scripts/refresh-public-key.sh`                | Regenerates `pages/public-key.pem` from the embedded root constant.|

## Security model

- The **root signing key** never leaves an offline machine. Its public half is embedded in every `excalibur-ctl` binary and mirrored in `pages/public-key.pem`.
- The **operational signing key** lives only as an [encrypted GitHub Environment Secret](https://docs.github.com/actions/security-guides/using-secrets-in-github-actions) on the `signing` environment, which requires a manual reviewer for every workflow run.
- All `main`-branch commits are signed and reviewed.
- Workflows trigger only on `repository_dispatch` (from the public landing page) or `workflow_dispatch` (from a maintainer). `pull_request_target` is forbidden.

## Reporting a vulnerability

Email **security@getexcalibur.com**. Please do not open a public issue for security-sensitive reports.

## License

The code and Pages content in this repository are released under the Apache License 2.0. See [`LICENSE`](LICENSE).

The Excalibur Proxy product itself is commercial software distributed via [AWS Marketplace](https://aws.amazon.com/marketplace) and [Azure Marketplace](https://azuremarketplace.microsoft.com/).
