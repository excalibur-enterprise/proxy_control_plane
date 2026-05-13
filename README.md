# Excalibur Proxy — Public Control Plane

Public, auditable artifact host for [Excalibur Proxy](https://excalibur-enterprise.github.io/proxy_control_plane/).

This repository hosts only **public, verifiable artifacts**:

- **Marketing and post-purchase pages** (in [`pages/`](pages/)) served via GitHub Pages.
- **Signed license bundles** committed by the (private) signing pipeline:
  - AWS bundles → [`entitlements/`](entitlements/)
  - Azure bundles → [`bundles/`](bundles/)
- **The root verification key** customers and auditors can pin to verify any license bundle Excalibur has ever issued (in [`pages/public-key.pem`](pages/public-key.pem) once published).
- **The active operational certificate(s)** signed by the offline root key (in [`pages/signing-keys/`](pages/signing-keys/)).

Everything in this repo is intentionally public so that customers can verify, byte-for-byte, what was signed on their behalf and which key signed it.

The signing key, marketplace API credentials, and fulfillment workflows live in a **separate private repository**. That repository commits the resulting signed bundles into this public repo, where they are served as static JSON over HTTPS. Issuance is therefore fully auditable as a public commit history, while the signing material itself never appears here.

## Why this exists

Excalibur Proxy is self-hosted: every byte of customer traffic stays in the customer's own AWS or Azure account. The only thing the proxy ever fetches from us is a small, signed **license bundle** that confirms the customer's entitlement (plan tier, workload limits, expiry).

1. Customer subscribes on AWS or Azure Marketplace.
2. Marketplace redirects them to [`pages/landing.html`](pages/landing.html) served from this repo.
3. The token is forwarded to the private signing pipeline.
4. The signing pipeline calls the marketplace's own resolution API to confirm the purchase, signs a license bundle with the offline operational key, and commits the bundle into this public repo.
5. The customer's proxy fetches the bundle from the public Pages URL on its normal refresh cycle.

Every issued bundle is a public commit. Every key rotation is a public commit. There is no hidden state.

## Verifying a license bundle

```bash
excalibur-ctl license verify ./bundle.json
```

The CLI ships an embedded copy of the long-lived root public key. The root signs short-lived **operational certificates**, and operational certs sign individual customer bundles. The current operational cert is published at [`pages/signing-keys/`](pages/signing-keys/) and rotated quarterly.

Wire format and signature scheme: [`pages/license-format.md`](pages/license-format.md).

## Layout

| Path                                  | Purpose                                                              |
| ------------------------------------- | -------------------------------------------------------------------- |
| `pages/index.html`                    | Marketing front page.                                                |
| `pages/landing.html`                  | Marketplace post-purchase landing page (AWS + Azure).                |
| `pages/license-format.md`             | License bundle wire format.                                          |
| `pages/public-key.pem`                | Long-lived root verification key (PKIX SPKI PEM).                    |
| `pages/signing-keys/`                 | Active operational certificate(s).                                   |
| `entitlements/`                       | Signed per-customer license bundles for AWS Marketplace.             |
| `bundles/`                            | Signed per-customer license bundles for Azure Marketplace.           |
| `.github/workflows/release-pages.yml` | Publishes `pages/`, `entitlements/`, and `bundles/` to GitHub Pages. |

## Security model

- The **root signing key** never leaves an offline machine. Its public half is embedded in every `excalibur-ctl` binary and mirrored in `pages/public-key.pem`.
- The **operational signing key** does **not** live in this repo. It lives only in the private signing repository as an encrypted GitHub Environment Secret on a `signing` environment that requires a manual reviewer for every workflow run.
- All `main`-branch commits are signed.
- This repo has no workflow that consumes secrets and no `repository_dispatch` trigger. The only workflow is the static Pages publisher.

## Reporting a vulnerability

Email **security@getexcalibur.com**. Please do not open a public issue for security-sensitive reports.

## License

The code and Pages content in this repository are released under the Apache License 2.0. See [`LICENSE`](LICENSE).

The Excalibur Proxy product itself is commercial software distributed via [AWS Marketplace](https://aws.amazon.com/marketplace) and [Azure Marketplace](https://azuremarketplace.microsoft.com/).
