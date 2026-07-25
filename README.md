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
