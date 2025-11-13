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

.PHONY: init
init: db-up
	@cd $(LIVE_DASHBOARD_DIR) && $(MAKE) init

.PHONY: run
start: db-up
	@cd $(DATA_PROCESSING_DIR) && $(MAKE) run &
	@cd $(LIVE_DASHBOARD_DIR) && $(MAKE) run

.PHONY: build
build:
	@cd $(DATA_PROCESSING_DIR) && $(MAKE) build
	@cd $(LIVE_DASHBOARD_DIR) && $(MAKE) build

.PHONY: down
down:
	@cd $(DATA_PROCESSING_DIR) && $(MAKE) down
	@cd $(LIVE_DASHBOARD_DIR) && $(MAKE) down
	@$(MAKE) db-down
