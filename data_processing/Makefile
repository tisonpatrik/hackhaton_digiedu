
.PHONY: db-status
db-status:
	cd .. && docker-compose ps postgres

.PHONY: run
run:
	cd .. && docker-compose up -d postgres
	cargo run

.PHONY: build
build:
	cargo build

.PHONY: test
test:
	cargo test
