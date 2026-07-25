#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

git submodule update --init --recursive

git submodule foreach '
  set -e
  git fetch origin --prune

  case "$name" in
    k8s-grader)
      default_branch="normal-aws-account"
      ;;
    *)
      default_ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD || true)"
      if [ -z "$default_ref" ]; then
        echo "[$name] Could not determine origin/HEAD" >&2
        exit 1
      fi

      default_branch="${default_ref#origin/}"
      ;;
  esac
  current_branch="$(git branch --show-current || true)"

  if git show-ref --verify --quiet "refs/heads/${default_branch}"; then
    git checkout "$default_branch"
  else
    git checkout -b "$default_branch" --track "origin/${default_branch}"
  fi

  if [ "$current_branch" = "$default_branch" ]; then
    echo "[$name] Already on ${default_branch}"
  else
    echo "[$name] Switched to ${default_branch}"
  fi
'
