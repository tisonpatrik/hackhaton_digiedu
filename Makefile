
DATA_PROCESSING_DIR = data_processing
LIVE_DASHBOARD_DIR = live_dashboard

.PHONY: db-up
db-up:
	docker-compose up -d postgres

.PHONY: db-down
db-down:
	docker-compose down

.PHONY: db-status
db-status:
	docker-compose ps postgres

.PHONY: data-processing-build
data-processing-build:
	cd $(DATA_PROCESSING_DIR) && cargo build

.PHONY: data-processing-run
data-processing-run: data-processing-build
	cd $(DATA_PROCESSING_DIR) && cargo run

.PHONY: live-dashboard-setup
live-dashboard-setup:
	cd $(LIVE_DASHBOARD_DIR) && mix setup

.PHONY: live-dashboard-run
live-dashboard-run:
	cd $(LIVE_DASHBOARD_DIR) && mix phx.server

.PHONY: clean
clean:
	cd $(DATA_PROCESSING_DIR) && cargo clean
	cd $(LIVE_DASHBOARD_DIR) && mix clean
