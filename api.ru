# api.ru
require 'rack/cors'
require File.expand_path('lib/api_server', __dir__)

api_app = ApiServer.new(root: File.expand_path('.', __dir__))

# Use a builder to apply CORS middleware
app_with_cors = Rack::Builder.new do
  use Rack::Cors do
    allow do
      origins '*'
      resource '/api/*', # Apply CORS to the API path
               headers: :any,
               methods: %i[get post options]
    end
  end
  use Rack::CommonLogger, api_app.settings.logger

  # Map /api to the ApiServer
  map '/api' do
    run api_app
  end
end

run app_with_cors
