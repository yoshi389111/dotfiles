# makefile for dotfiles

# ref. https://postd.cc/auto-documented-makefile/
.DEFAULT_GOAL = help
.PHONY: help
help: ## Show help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: update
update: ## install or Update symlinks
	scripts/update.sh

