# Swiftkiq

## Summary

Swiftkiq is the job queue system for general purpose.

## Examples

please host local redis-server

```
$ brew install redis
$ git clone https://github.com/ainame/Swiftkiq.git
$ cd Swiftkiq/Examples
$ swift build
$ redis-sever &
$ ./.build/debug/swiftkiq_example
```

## Acknowledgement

* original author is @mperham on [Sidekiq](https://github.com/mperham/sidekiq)
