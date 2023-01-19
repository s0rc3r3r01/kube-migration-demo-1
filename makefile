SHELL := /bin/bash

# ==============================================================================
# Testing running system

# Deploy First Mentality
#
# Other commands to install.
# go install github.com/divan/expvarmon@latest
# go install github.com/rakyll/hey@latest
#
# For full Kind v0.17 release notes: https://github.com/kubernetes-sigs/kind/releases/tag/v0.17.0
#
# For testing a simple query on the system. Don't forget to `make seed` first.
# curl -il --user "admin@example.com:gophers" http://sales-service.sales-system.svc.cluster.local:3000/v1/users/token/54bb2165-71e1-41a6-af3e-7da4a0e1e2c1
# export TOKEN="COPY TOKEN STRING FROM LAST CALL"
# curl -il -H "Authorization: Bearer ${TOKEN}" http://sales-service.sales-system.svc.cluster.local:3000/v1/users/1/2
#
# For testing load on the service.
# hey -m GET -c 100 -n 10000 -H "Authorization: Bearer ${TOKEN}" http://sales-service.sales-system.svc.cluster.local:3000/v1/users/1/2
#
#
# Testing coverage.
# go test -coverprofile p.out
# go tool cover -html p.out
#

# ==============================================================================
# Building containers

# $(shell git rev-parse --short HEAD)
VERSION := 1.0

all: microservice run

microservice:
	docker build \
		-f Dockerfile \
		-t kube-migration-demo-1:$(VERSION) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

run:
	docker run \
	-p 3000:3000 \
	-t kube-migration-demo-1:$(VERSION) \
# ==============================================================================
# Running from within k8s/kind

KIND_CLUSTER := ardan-starter-cluster

dev-up:
	kind create cluster \
		--image kindest/node:v1.25.3@sha256:f52781bc0d7a19fb6c405c2af83abfeb311f130707a0e219175677e366cc45d1 \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/dev/kind-config.yaml
	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner
	
dev-down:
	kind delete cluster --name $(KIND_CLUSTER)

dev-load:
	cd zarf/k8s/dev/sales; kustomize edit set image kube-migration-demo-1-image=kube-migration-demo-1:$(VERSION)
	kind load docker-image kube-migration-demo-1:$(VERSION) --name $(KIND_CLUSTER)

	cd zarf/k8s/dev/sales; kustomize edit set image metrics-image=metrics:$(VERSION)
	kind load docker-image metrics:$(VERSION) --name $(KIND_CLUSTER)

dev-apply:

	kustomize build zarf/k8s/dev/database | kubectl apply -f -
	kubectl wait --timeout=120s --namespace=sales-system --for=condition=Available deployment/database

	kustomize build zarf/k8s/dev/sales | kubectl apply -f -
	kubectl wait --timeout=120s --namespace=sales-system --for=condition=Available deployment/sales

dev-restart:
	kubectl rollout restart deployment sales --namespace=sales-system

dev-update: all dev-load dev-restart

dev-update-apply: all dev-load dev-apply

dev-logs:
	kubectl logs --namespace=sales-system -l app=sales --all-containers=true -f --tail=100 --max-log-requests=6 | go run app/tooling/logfmt/main.go -service=kube-migration-demo-1

dev-logs-init:
	kubectl logs --namespace=sales-system -l app=sales -f --tail=100 -c init-migrate
	kubectl logs --namespace=sales-system -l app=sales -f --tail=100 -c init-seed

dev-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

dev-describe:
	kubectl describe nodes
	kubectl describe svc

dev-describe-deployment:
	kubectl describe deployment --namespace=sales-system sales

dev-describe-sales:
	kubectl describe pod --namespace=sales-system -l app=sales

liveness:
	curl -il http://sales-service.sales-system.svc.cluster.local:4000/debug/liveness

readiness:
	curl -il http://sales-service.sales-system.svc.cluster.local:4000/debug/readiness


# ==============================================================================
# Running tests within the local computer
# go install honnef.co/go/tools/cmd/staticcheck@latest
# go install golang.org/x/vuln/cmd/govulncheck@latest

test:
	CGO_ENABLED=0 go test -count=1 ./...
	CGO_ENABLED=0 go vet ./...
	staticcheck -checks=all ./...
	govulncheck ./...

# ==============================================================================
# Modules support

deps-reset:
	git checkout -- go.mod
	go mod tidy
	go mod vendor

tidy:
	go mod tidy
	go mod vendor

deps-list:
	go list -m -u -mod=readonly all

deps-upgrade:
	go get -u -v ./...
	go mod tidy
	go mod vendor

deps-cleancache:
	go clean -modcache

list:
	go list -mod=mod all
