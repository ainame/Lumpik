#!/bin/sh -xe
sed -e "s/\/\/ Target(name: \"Benchmark\", dependencies: \[\"Lumpik\"\]),/Target(name: \"Benchmark\", dependencies: \[\"Lumpik\"\]),/" -i "" Package.swift
sed -e "s/\"Sources\/Benchmark\",/\/\/ \"Sources\/Benchmark\",/" -i "" Package.swift
swift build -c release
ruby scripts/enqueue_benchmark_job.rb
./.build/release/Benchmark
sed -e "s/Target(name: \"Benchmark\", dependencies: \[\"Lumpik\"\]),/\/\/ Target(name: \"Benchmark\", dependencies: \[\"Lumpik\"\]),/" -i "" Package.swift
sed -e "s/\/\/ \"Sources\/Benchmark\",/\"Sources\/Benchmark\",/" -i "" Package.swift
