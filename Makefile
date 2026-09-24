.PHONY: help install server clickhouse clickhouse-prod clickhouse-stop clickhouse-postgres-remote postgres postgres-client postgres-prod postgres-stop

require = \
	  $(foreach 1,$1,$(__require))
__require = \
	    $(if $(value $1),, \
	    $(error Provide required parameter: $1$(if $(value 2), ($(strip $2)))))

help:
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: ## Run the initial setup
	mix deps.get
	mix ecto.create
	mix ecto.migrate
	mix download_country_database
	npm install --prefix assets
	npm install --prefix tracker
	npm run deploy --prefix tracker

server: ## Start the web server
	mix phx.server

CH_FLAGS ?= --detach -p 8123:8123 -p 9000:9000 --ulimit nofile=262144:262144 --name plausible_clickhouse --env CLICKHOUSE_SKIP_USER_SETUP=1

clickhouse: ## Start a container with a recent version of clickhouse
	docker run $(CH_FLAGS) --network host --volume=$$PWD/.clickhouse_db_vol:/var/lib/clickhouse --volume=$$PWD/.clickhouse_config:/etc/clickhouse-server/config.d clickhouse/clickhouse-server:latest-alpine

clickhouse-client: ## Connect to clickhouse
	docker exec -it plausible_clickhouse clickhouse-client -d plausible_events_db

clickhouse-prod: ## Start a container with the same version of clickhouse as the one in prod
	docker run $(CH_FLAGS) --volume=$$PWD/.clickhouse_db_vol_prod:/var/lib/clickhouse clickhouse/clickhouse-server:25.11.5.8-alpine

clickhouse-stop: ## Stop and remove the clickhouse container
	docker stop plausible_clickhouse && docker rm plausible_clickhouse

clickhouse-postgres-remote: ## Create postgres_remote database in ClickHouse for querying PostgreSQL
	$(eval POSTGRES_IP := $(shell docker inspect plausible_db --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'))
	@docker exec plausible_clickhouse clickhouse-client --query "DROP DATABASE IF EXISTS postgres_remote; CREATE DATABASE postgres_remote ENGINE = PostgreSQL('$(POSTGRES_IP):5432', 'plausible_dev', 'postgres', 'postgres');"

PG_FLAGS ?= --detach -e POSTGRES_PASSWORD="postgres" -p 5432:5432 --name plausible_db

postgres: ## Start a container with a recent version of postgres
	docker run $(PG_FLAGS) --volume=plausible_db:/var/lib/postgresql/docker postgres:latest

postgres-client: ## Connect to postgres
	docker exec -it plausible_db psql -U postgres -d plausible_dev

postgres-prod: ## Start a container with the same version of postgres as the one in prod
	docker run $(PG_FLAGS) --volume=plausible_db_prod:/var/lib/postgresql/docker postgres:18

postgres-stop: ## Stop and remove the postgres container
	docker stop plausible_db && docker rm plausible_db

browserless:
	docker run -e "TOKEN=dummy_token" -p 3000:3000 --network host ghcr.io/browserless/chromium

# MinIO via GitHub release binaries (not Docker).
# Docker Hub and quay.io both reject anonymous pulls of minio/minio as of 2026-09,
# which broke CI `make minio`. Legacy community binaries remain on GitHub Releases.
MINIO_RELEASE ?= RELEASE.2025-09-07T16-13-09Z
MC_RELEASE ?= RELEASE.2025-08-13T08-35-41Z
MINIO_BIN_DIR ?= .minio-bin
MINIO_DATA_DIR ?= .minio-data

minio: ## Start a local MinIO (S3) for tests via release binaries
	@set -e; \
	OS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
	ARCH=$$(uname -m); \
	case "$$ARCH" in x86_64|amd64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; *) echo "unsupported arch: $$ARCH"; exit 1 ;; esac; \
	mkdir -p $(MINIO_BIN_DIR) $(MINIO_DATA_DIR); \
	MINIO_URL="https://github.com/minio/minio/releases/download/$(MINIO_RELEASE)/minio.$${OS}-$${ARCH}.$(MINIO_RELEASE)"; \
	MC_URL="https://github.com/minio/mc/releases/download/$(MC_RELEASE)/mc.$${OS}-$${ARCH}.$(MC_RELEASE)"; \
	if [ ! -x $(MINIO_BIN_DIR)/minio ]; then curl -fsSL "$$MINIO_URL" -o $(MINIO_BIN_DIR)/minio && chmod +x $(MINIO_BIN_DIR)/minio; fi; \
	if [ ! -x $(MINIO_BIN_DIR)/mc ]; then curl -fsSL "$$MC_URL" -o $(MINIO_BIN_DIR)/mc && chmod +x $(MINIO_BIN_DIR)/mc; fi; \
	if [ -f $(MINIO_BIN_DIR)/minio.pid ] && kill -0 $$(cat $(MINIO_BIN_DIR)/minio.pid) 2>/dev/null; then \
		echo "MinIO already running (pid $$(cat $(MINIO_BIN_DIR)/minio.pid))"; \
	else \
		MINIO_ROOT_USER=minioadmin MINIO_ROOT_PASSWORD=minioadmin \
			$(MINIO_BIN_DIR)/minio server $(MINIO_DATA_DIR) --address ":10000" --console-address ":10001" \
			>$(MINIO_BIN_DIR)/minio.log 2>&1 & echo $$! > $(MINIO_BIN_DIR)/minio.pid; \
		echo "MinIO started (pid $$(cat $(MINIO_BIN_DIR)/minio.pid))"; \
	fi; \
	i=0; \
	until $(MINIO_BIN_DIR)/mc alias set local http://127.0.0.1:10000 minioadmin minioadmin >/dev/null 2>&1; do \
		i=$$((i+1)); if [ $$i -gt 30 ]; then echo "MinIO failed to become ready:"; tail -n 50 $(MINIO_BIN_DIR)/minio.log; exit 1; fi; \
		sleep 1; \
	done; \
	$(MINIO_BIN_DIR)/mc mb --ignore-existing local/test-exports; \
	$(MINIO_BIN_DIR)/mc mb --ignore-existing local/test-imports

minio-stop: ## Stop the local MinIO process started by `make minio`
	@if [ -f $(MINIO_BIN_DIR)/minio.pid ]; then \
		kill $$(cat $(MINIO_BIN_DIR)/minio.pid) 2>/dev/null || true; \
		rm -f $(MINIO_BIN_DIR)/minio.pid; \
	fi; \
	docker stop plausible_minio 2>/dev/null || docker stop plausible-minio 2>/dev/null || true

sso:
	$(call require, integration_id)
	@echo "Setting up local IdP service..."
	@docker run --name=idp \
  -p 8080:8080 \
  -e SIMPLESAMLPHP_SP_ENTITY_ID=http://localhost:8000/sso/$(integration_id) \
  -e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=http://localhost:8000/sso/saml/consume/$(integration_id) \
  -v $$PWD/extra/fixture/authsources.php:/var/www/simplesamlphp/config/authsources.php -d kenchan0130/simplesamlphp

	@sleep 2

	@echo "Use the following IdP configuration:" 
	@echo ""
	@echo "Sign-in URL: http://localhost:8080/simplesaml/saml2/idp/SSOService.php"
	@echo ""
	@echo "Entity ID: http://localhost:8080/simplesaml/saml2/idp/metadata.php"
	@echo ""
	@echo "PEM Certificate:"
	@curl http://localhost:8080/simplesaml/module.php/saml/idp/certs.php/idp.crt 2>/dev/null
	@echo ""
	@echo ""
	@echo "Following accounts are configured:"
	@echo "- user@plausible.test / plausible"
	@echo "- user1@plausible.test / plausible"
	@echo "- user2@plausible.test / plausible"
	@echo ""
	@echo "Run plausible application server with ALLOW_RESERVED_IPS=true"
	
sso-stop:
	docker stop idp
	docker remove idp

generate-corefile:
	$(call require, domain_id)
	domain_id=$(domain_id) envsubst < $(PWD)/extra/fixture/Corefile.template > $(PWD)/extra/fixture/Corefile.gen.$(domain_id)

mock-dns: generate-corefile
	$(call require, domain_id)
	docker run --rm -p 5354:53/udp -v $(PWD)/extra/fixture/Corefile.gen.$(domain_id):/Corefile coredns/coredns:latest -conf Corefile

loadtest-server:
	@echo "Ensure your OTP installation is built with --enable-lock-counter"
	MIX_ENV=load ERL_FLAGS="-emu_type lcnt +Mdai max" iex -S mix do phx.digest + phx.server

loadtest-client:
	@echo "Set your limits for file descriptors/ephemeral ports high... Test begins shortly"
	@sleep 5
	k6 run test/load/script.js  
