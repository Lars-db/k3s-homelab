.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash

.PHONY: help install uninstall bootstrap validate render status clean-demo

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ## Install k3s (requires sudo)
	sudo ./scripts/install-k3s.sh

uninstall: ## Remove k3s and ALL data (requires sudo, destructive)
	sudo ./scripts/uninstall-k3s.sh

bootstrap: ## Apply all manifests to the cluster
	./scripts/bootstrap.sh

render: ## Render kustomize output locally
	kubectl kustomize manifests

validate: ## Dry-run apply against the cluster (server-side)
	kubectl apply -k manifests --dry-run=server

status: ## Show demo workloads
	kubectl -n demo get deploy,svc,ingress,hpa,pods

clean-demo: ## Delete the demo app (keeps the cluster)
	kubectl delete -k manifests --ignore-not-found
