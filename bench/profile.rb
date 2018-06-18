# frozen_string_literal: true

require 'benchmark'
include Benchmark

require 'rack/test'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'elastic-apm'

class App
  def initialize(config = {})
    @config = ElasticAPM::Config.new(
      {
        environment: 'bench',
        enabled_environments: ['bench'],
        disable_send: true
      }.merge(config)
    )
    @serializer = ElasticAPM::Serializers::Transactions.new(@config)
    @mock_env = Rack::MockRequest.env_for('/')
  end

  attr_reader :mock_env, :serializer

  def start
    @agent = ElasticAPM.start(@config)
  end

  def stop
    ElasticAPM.stop
  end
end

def perform(app, count: 1000)
  app.start

  transactions = count.times.map do |i|
    ElasticAPM.transaction "Transaction##{i}",
      context: ElasticAPM.build_context(app.mock_env) do
      ElasticAPM.span('Number one') { 'ok 1' }
      ElasticAPM.span('Number two') { 'ok 2' }
      ElasticAPM.span('Number three') { 'ok 3' }
    end
  end

  app.serializer.build_all(transactions)

  app.stop
end

def with_app(config = {})
  app = App.new(config)
  app.start
  result = yield app
  app.stop

  result
end

def avg(benchmarks)
  [benchmarks.reduce(Tms.new(0), &:+) / benchmarks.length]
end

def banner(text)
  puts '=' * 78
  puts text.rjust((78 / 2) + (text.length / 2))
  puts '=' * 78
end

def do_bench(config = {})
  Benchmark.benchmark(CAPTION, 7, FORMAT, 'avg:') do |x|
    benchmarks =
      with_app(config) do |app|
        10.times.map do |i|
          x.report("run[#{i}]") { perform(app) }
        end
      end

    avg(benchmarks)
  end
end

banner 'Default settings'
do_bench

banner "With transaction_sample_rate = 0"
do_bench(transaction_sample_rate: 0)
