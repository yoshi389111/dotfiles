# makefile for dotfiles
# ref. https://postd.cc/auto-documented-makefile/

.DEFAULT_GOAL = help
help: ## Show help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
.PHONY: help

update: ## Update symlinks
	scripts/update.sh
.PHONY: update

install: ## Overwrite files and create symlinks
	scripts/install.sh
.PHONY: install

