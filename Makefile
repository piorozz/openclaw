# OpenClaw fork: sync upstream into a branch, then merge to main.
# Run from repo root: make openclaw-update

.PHONY: help openclaw-update setup-remotes

help: ## List make targets and descriptions
	@grep -E '^([a-zA-Z0-9_-]+):[^#]*## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

openclaw-update: ## Sync upstream openclaw into a branch, then merge to main
	@bash ./scripts/custom/openclaw-update.sh

setup-remotes: ## Add upstream remote and fetch main (idempotent; run once after clone)
	@git remote get-url upstream 2>/dev/null || git remote add upstream https://github.com/openclaw/openclaw.git; \
	git fetch upstream main
