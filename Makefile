.DEFAULT_GOAL := build
.PHONY: clean test build

clean:
	@rm -rf .build/*-apple-macosx

test:
	@swift test

build:
	@swift build -c release

