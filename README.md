# k8s-game-platform

Parent repository for the Kubernetes game platform.

## Included submodules

- `k8s-grader` - grader backend, student portal, deployment flow
- `k8s-game-rule` - exercise and test content
- `k8s-isekai` - RPG exercise client
- `doom.ts` - Doom exercise client

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
