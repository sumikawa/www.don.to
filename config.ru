require 'middleman-core/load_paths'
Middleman.setup_load_paths

require 'middleman-core'
require 'middleman-core/rack'

require 'fileutils'
FileUtils.mkdir('log') unless File.exist?('log')
Middleman::Logger.singleton("log/#{ENV.fetch('RACK_ENV', nil)}.log")

app = Middleman::Application.new

run Middleman::Rack.new(app).to_app
