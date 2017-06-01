#!/bin/sh -xe
swift build -c release
ruby scripts/enqueue_benchmark_job.rb
./.build/release/Benchmark
