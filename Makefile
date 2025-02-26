.PHONY: lint_app lint_modules lint_all format_app format_modules format_all all

.DEFAULT_GOAL := all

lint_app:
	swift format lint -s --configuration .swift-format -r App
lint_modules:
	swift format lint -s --configuration .swift-format -r Sources Tests
lint_all: lint_app lint_modules
format_app:
	swift format format --configuration .swift-format -ipr App
format_modules:
	swift format format --configuration .swift-format -ipr Sources Tests
format_all: format_app format_modules
all: format_all lint_all
