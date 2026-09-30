# k8s-game-platform

Parent repository for the Kubernetes game platform.

## Included submodules and clients

- `k8s-grader` - grader backend, student portal, deployment flow
- `k8s-game-rule` - exercise and test content
- `k8s-isekai` - RPG exercise client
- `doom.ts` - Doom exercise client
- `hkzero` - Hong Kong Zero 3D exercise client ([Educational Clone & Copyright Disclaimer](hkzero/DISCLAIMER.md))

## Clone with submodules

```bash
git clone https://github.com/wongcyrus/k8s-game-platform.git
cd k8s-game-platform
git submodule update --init --recursive
```

## Check out all submodules

```bash
./checkout-submodules.sh
```

This initializes the submodules, fetches `origin`, and checks out each submodule's default branch (for example `main` or `master`).

## Deploy from the superproject

```bash
cp .env.example .env
./deploy.sh
```

The deploy flow now uses separate SAM config files:

- `k8s-grader/k8s-grader-api/samconfig.dev.toml`
- `k8s-grader/k8s-grader-api/samconfig.prod.toml`

Use dev by default, or select prod explicitly:

```bash
./deploy.sh
ENV=prod ./deploy.sh
```

If `.env` exists at the repo root, `deploy.sh` loads it before running the grader deploy flow.

## Undeploy from the superproject

```bash
./undeploy.sh --yes
```

## Updating a component

```bash
cd doom.ts
git pull
cd ..
git add doom.ts
git commit -m "Update doom.ts"
```

## Layout

This repository is the integration/orchestration layer. Each submodule remains an independent repository with its own history, issues, and release cadence.

## Attribution & Copyright Notice for `hkzero`

The `hkzero/` directory is an **educational clone** adapted from [Hong Kong Zero (港域時空)](https://hongkongzero.com/) solely for academic demonstration and hands-on Kubernetes grading at the Hong Kong Institute of Information Technology (HKIIT / VTC). 

- **Special Thanks to Original Author:** We express our deepest gratitude and highest respect to **Arthur and the Hong Kong Zero team** for creating this groundbreaking 3D WebGL reconstruction of Hong Kong. Please experience and support the authentic original game at [hongkongzero.com](https://hongkongzero.com/)!
- **No Official Permission:** No commercial license or official permission was obtained from the original game developers.
- **Fair Use & Open Data:** Over 95% of the data volume consists of HKSAR Government CSDI Open Data, OpenStreetMap (ODbL), and CC0/CC-BY assets. This client is operated strictly for non-commercial educational and interoperability research.
- **Takedown Policy:** For copyright concerns or takedown requests, please refer to the full [hkzero/DISCLAIMER.md](hkzero/DISCLAIMER.md) or open an issue.
