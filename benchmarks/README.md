# About this benchmarks

Benchmarks performed inspired from excon's benchmarking tool.

## Environments

- MacBook Pro (Retina, 15-inch, Mid 2015), 2.2 GHz Intel Core i7, 16 GB 1600 MHz DDR3.
- Crystal 0.35.1 (2020-06-19) LLVM: 10.0.0
- Clients
  - buit-in HTTP::Client
  - create v0.26.1
  - halite v0.10.8

## Result

```
Tach times: 10000
                          Tach                Total
                         crest             8.0365ms
                        halite             7.9538ms (fastest)
           halite (persistent)             8.0205ms
         built-in HTTP::Client             8.0256ms
```

## Test yourself

```crystal
$ shards build --release --no-debug
$ ./bin/run_benchmark
```
