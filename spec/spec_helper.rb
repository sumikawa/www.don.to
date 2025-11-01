require 'rspec'
require 'middleman-core'
require 'middleman-core/load_paths'
require 'middleman-core/rack'

Middleman.setup_load_paths

module Middleman
  module RSpec
    def app
      @@app ||= ::Middleman::Application.new do
        set :root, File.expand_path(File.join(File.dirname(__FILE__), '..'))
        set :environment, :development
        set :show_exceptions, false
      end
    end
  end
end

RSpec.configure do |config|
  config.include Middleman::RSpec
end
