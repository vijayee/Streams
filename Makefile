build:
	mkdir -p build
test: build
	mkdir -p build/test
test/Streams: test Streams/test/*.pony
	#corral fetch
	corral run -- ponyc Streams/test -o build/test --debug
test/execute: test/Streams
	./build/test/test
clean:
	rm -rf build

.PHONY: clean test
