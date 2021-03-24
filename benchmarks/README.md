# About this benchmarks

Benchmarks performed inspired from excon's benchmarking tool.

## Environments

- MacBook Pro (Retina, 15-inch, Mid 2015), 2.2 GHz Intel Core i7, 16 GB 1600 MHz DDR3.
- Crystal 1.0.0 [dd40a2442] (2021-03-22) LLVM: 10.0.0
- Clients
  - buit-in HTTP::Client
  - create v0.27.0
  - halite v0.12.0

## Result

```
Tach times: 10000
                          Tach                Total
                         crest           427.5995µs
                        halite           417.5273µs (fastest)
           halite (persistent)           433.7772µs
         built-in HTTP::Client           448.7872µs
```

## Test yourself

```crystal
$ shards build --release --no-debug
$ ./bin/run_benchmark
```
