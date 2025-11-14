.PHONY: init

.PHONY: migrate
migrate:
	mix ecto.migrate

.PHONY: drop
drop:
	mix ecto.drop

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


