# Lumpik

## Summary

Lumpik is the job queue system for general purpose.

## Features

* can consume your all of CPU-cores on 1 process
* can create a worker which has type-safe argument
* can deploy your app as a binary file

## Examples

see [https://github.com/ainame/Lumpik/tree/master/Sources/Examples/](https://github.com/ainame/Lumpik/tree/master/Sources/Examples/)

## Benchmark

Please host local redis-server at firtst.
Do 100,000 no-op jobs, and measure throughput.

```
$ git clone https://github.com/ainame/Lumpik.git
$ cd Lumpik
$ gem install redis
$ scripts/load.sh
```

## Acknowledgement

* original author is @mperham on [Sidekiq](https://github.com/mperham/sidekiq)
