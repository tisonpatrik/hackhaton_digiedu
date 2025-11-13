.PHONY: init

.PHONY: migrate
migrate:
	mix ecto.migrate

init:
	cd .. && docker-compose up -d postgres
	mix setup
	@make migrate

.PHONY: build
build:
	mix assets.build

.PHONY: run
run:
	mix phx.server --open


