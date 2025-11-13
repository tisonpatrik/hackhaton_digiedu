.PHONY: init
init:
	mix setup

.PHONY: db-up
db-up:
	cd .. && docker-compose up -d postgres
	@make migrate

.PHONY: run
run:
	mix phx.server --open

.PHONY: migrate
migrate:
	mix ecto.migrate


.PHONY: build
build:
	mix assets.build