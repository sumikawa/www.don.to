# lib/api_server.rb

require 'sinatra/base'
require 'json'

class ApiServer < Sinatra::Base
  def initialize(app = nil, root: Dir.pwd)
    super(app)
    @root = root
  end

  # Read a file
  get '/*' do
    content_type :json
    # The path is captured from the URL, remove leading slash
    file_path = params['splat'].first.sub(%r{^/}, '')

    # Only allow access to files within the 'source' directory
    source_dir = File.expand_path('source', @root)
    full_path = File.join(source_dir, file_path)

    # Security check: ensure the final path is within the source directory
    unless File.expand_path(full_path).start_with?(source_dir)
      status 403
      return { error: 'Forbidden: Access is restricted to the source directory.' }.to_json
    end

    if File.exist?(full_path)
      { path: file_path, content: File.read(full_path) }.to_json
    else
      status 404
      { error: "File not found at #{full_path}" }.to_json
    end
  end

  # Write a file
  post '/' do
    content_type :json
    begin
      request_payload = JSON.parse(request.body.read)
      # The path is in the request body, remove leading slash
      file_path = request_payload['path'].sub(%r{^/}, '')
      content = request_payload['content']

      if file_path.nil? || content.nil?
        status 400
        return { error: 'Bad Request: path and content are required.' }.to_json
      end

      # Only allow writing to files within the 'source' directory
      source_dir = File.expand_path('source', @root)
      full_path = File.join(source_dir, file_path)

      # Security check: ensure the final path is within the source directory
      unless File.expand_path(full_path).start_with?(source_dir)
        status 403
        return { error: 'Forbidden: Access is restricted to the source directory.' }.to_json
      end

      File.write(full_path, content)
      { success: true, path: file_path }.to_json
    rescue JSON::ParserError
      status 400
      { error: 'Invalid JSON' }.to_json
    rescue => e
      status 500
      { error: e.message }.to_json
    end
  end
end
