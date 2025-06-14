.PHONY: test test-coverage coverage-html lint clean generate kafka-up kafka-down kafka-setup docs

# Run tests
test:
	dart test

# Run tests with coverage and exclude infrastructure
test-coverage:
	dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib
	lcov --remove coverage/lcov.info 'lib/src/infrastructure/*' -o coverage/lcov.info

# Generate HTML coverage report and open in browser
coverage-html:
	genhtml coverage/lcov.info -o coverage/html
	firefox coverage/html/index.html

# Run linter
lint:
	dart analyze

# Clean coverage files
clean:
	rm -rf coverage/

# Generate FFI bindings
generate:
	dart run ffigen --config=ffigen.yaml

# Start Kafka cluster
kafka-up:
	docker compose up -d

# Stop Kafka cluster
kafka-down:
	docker compose down

# Setup Kafka with test topics
kafka-setup:
	./scripts/setup-kafka.sh

# Generate documentation
docs:
	dart doc
	@echo "📚 Documentation generated in doc/ directory"
