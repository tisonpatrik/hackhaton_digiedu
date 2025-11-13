.PHONY: run
run:
	cd .. && docker-compose up -d postgres
	cd ../live_dashboard && make migrate
	cargo run

.PHONY: build
build:
	cargo build


.PHONY: test
test:
	cargo test
