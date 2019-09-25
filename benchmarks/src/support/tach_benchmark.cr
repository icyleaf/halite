module Benchmark
  def self.tach(times : Int32)
    {% if !flag?(:release) %}
      puts "Warning: benchmarking without the `--release` flag won't yield useful results"
    {% end %}

    job = Tach::Job.new(times)
    yield job
    job.execute
    job.report
    job
  end

  module Tach
    class Job
      def initialize(@times : Int32 = 1)
        @benchmarks = [] of {String, ->}
        @results = {} of String => Float64
      end

      def report(label : String, &block)
        @benchmarks << {label, block}
      end

      def execute
        @benchmarks.each do |benchmark|
          GC.collect

          label, block = benchmark
          durations = [] of Float64
          @times.times do
            before = Time.utc
            block.call
            after = Time.utc

            durations << (after - before).total_seconds
          end

          average = durations.sum.to_f / @times.to_f

          @results[label] = average
        end
      end

      def report
        fastest = @results.min_by { |_, value| value }

        puts "Tach times: #{@times}"
        printf "%30s %20s\n", "Tach", "Total"
        @results.each do |label, result|
          mark = label == fastest.first ? " (fastest)" : ""

          printf "%30s %20s%s\n", label, human_mean(result), mark
        end
      end

      private def human_mean(iteration_time)
        case Math.log10(iteration_time)
        when 0..Float64::MAX
          digits = iteration_time
          suffix = "s"
        when -3..0
          digits = iteration_time * 1000
          suffix = "ms"
        when -6..-3
          digits = iteration_time * 1_000_000
          suffix = "µs"
        else
          digits = iteration_time * 1_000_000_000
          suffix = "ns"
        end

        "#{digits.round(4).to_s.rjust(6)}#{suffix}"
      end
    end
  end
end
