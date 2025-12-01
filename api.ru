# api.ru
require 'rack/cors'
require ::File.expand_path('lib/api_server', __dir__)

# CORS middleware configuration
use Rack::Cors do
  allow do
    origins '*'
    resource '*', # All resources
             headers: :any,
             methods: [:get, :post, :options]
  end
end

# API server application
run ApiServer.new(root: ::File.expand_path('.', __dir__))
