# Makefile for generating/updating base helm charts
SHELL := /bin/bash

.PHONY: create
create:
	helm create $(NAME)
	rm -rf $(PWD)/$(NAME)/charts
	rm -rf $(PWD)/$(NAME)/templates/tests

# Update the version in Chart.yaml first before bumping the version here
.PHONY: bump
bump:
	helm package $(NAME)
	helm repo index .
