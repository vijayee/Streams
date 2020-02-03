build:
	mkdir -p build
test: build
	mkdir -p build/test
test/Streams: test Streams/test/*.pony
	stable fetch
	stable env ponyc Streams/test -o build/test --debug
test/execute: test/Streams
	./build/test/test
clean:
	rm -rf build

.PHONY: clean test
