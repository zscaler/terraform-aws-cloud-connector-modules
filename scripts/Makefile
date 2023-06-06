# Define variables
ZIP_FILE := zscaler_cc_lambda_service.zip
SRC_DIR := zscaler_cc_lambda_service
DEST_TARGET_DIR := artifacts

REQ_FILE := $(SRC_DIR)/requirements.txt

.PHONY: build clean

build:
	@echo "Creating virtual environment..."
	python3.9 -m venv venv
	@echo "Activating virtual environment..."
	. venv/bin/activate && \
	pip install -r $(REQ_FILE) && \
	deactivate
	@echo "Zipping files..."
	(cd $(SRC_DIR) && zip -r $(ZIP_FILE) .)
	mv $(SRC_DIR)/$(ZIP_FILE) $(DEST_TARGET_DIR)/$(ZIP_FILE)
	@echo "Cleaning up..."
	rm -rf venv

clean:
	rm -f $(DEST_TARGET_DIR)/$(ZIP_FILE)
