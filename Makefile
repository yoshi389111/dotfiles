# makefile for dotfiles

.PHONY: update
update:
	script/update.sh

.PHONY: install
install:
	script/install.sh

.PHONY: help
help:
	echo
