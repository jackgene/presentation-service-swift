.DEFAULT_GOAL := build
.PHONY: clean build

clean:
	@rm -rf .build/*-apple-macosx

build: clean
	@swift build -c release

