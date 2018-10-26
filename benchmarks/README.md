# About this benchmarks

Benchmarks performed inspired from excon's benchmarking tool.

## Environments

- MacBook Pro (Retina, 15-inch, Mid 2015), 2.2 GHz Intel Core i7, 16 GB 1600 MHz DDR3.
- Crystal 0.26.0 (llvm 6.0.1)
- Clients
  - cossack v0.1.4
  - create v0.14.0
  - halite v0.6.0

## Result

```
Tach times: 1000
                          Tach                Total
                       cossack             6.9514ms (fastest)
                         crest             9.0551ms
                        halite             7.8958ms
           halite (persistent)             8.0661ms
          built-in http client             7.8528ms
```

## Test yourself

```crystal
$ shards build --release --no-debug
$ ./bin/run_benchmark
```
