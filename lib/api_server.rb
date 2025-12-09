# lib/api_server.rb

require 'sinatra/base'
require 'json'
require_relative 'tabelog'
require_relative '../helpers/link_helpers'
require 'logger' # Add this line

include LinkHelpers

class ApiServer < Sinatra::Base
  set :host_authorization, { permitted_hosts: ['localhost', 'stage.don.to'] }

  # Configure logging
  configure do
    enable :logging
    log_file = File.new('logs/api_server.log', 'a+')
    log_file.sync = true
    set :logger, Logger.new(log_file)
  end

  def initialize(app = nil, root: Dir.pwd)
    super(app)
    @root = root
  end

      # Read a file
    get '/*' do
      logger.info "GET request for path: #{params['splat'].first}" # Added log statement
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

      # Only allow writing to files within the 'source' directory
      source_dir = File.expand_path('source', @root)
      full_path = File.join(source_dir, file_path)

      content = apply_content_filters(content, full_path)

      if file_path.nil? || content.nil?
        status 400
        return { error: 'Bad Request: path and content are required.' }.to_json
      end

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
      logger.error(e.message)
      logger.error(e.backtrace.join("\n"))
      status 500
      { error: e.message }.to_json
    end
  end

  private

  def apply_content_filters(content, full_path)
    content.lines.map do |line|
      if line.strip.start_with?('https://tabelog.com/')
        begin
          tabelog(line.strip)
        rescue
          line
        end
      elsif line.strip.match(/l<%= image "(.*)" %>/)
        file = $1
        dirname = full_path.sub('.html.md.erb', '')
        original_dir = dirname.sub('src/www/source', 'images')
        if File.exist?("#{original_dir}/#{file}.jpg")
          sips_cmd = "sips -r 270 #{original_dir}/#{file}.jpg"
        else
          sips_cmd = "sips -r 270 #{original_dir}/#{file}.heic"
        end
        system "#{sips_cmd} > /dev/null 2>&1"
        line.sub(/^l/, '')
      else
        line
      end
    end.join
  end
end
