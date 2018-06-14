# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'stackprof'
require 'rack/test'
require './boot'

env = Rack::MockRequest.env_for('/')

puts 'Running '
profile = StackProf.run(mode: :wall, out: 'tmp/out-wall.dump', raw: true) do
  100.times do
    _, _, body = Bench::Application.call env
    # puts body.join
    print '.'
  end
end
puts ''

# StackProf::Report.new(profile).print_text
