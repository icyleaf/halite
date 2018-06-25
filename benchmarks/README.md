# About this benchmarks

Benchmarks performed inspired from excon's benchmarking tool.

## Result

```
                          Tach                Total
                       cossack              4.325ms
                         crest             4.3342ms
                        halite             6.2203ms
           halite (persistent)             4.4749ms
          built-in http client             3.9897ms (fastest)
```

## Test yourself

```crystal
$ shards build --release --no-debug
$ ./bin/run_benchmark
```
