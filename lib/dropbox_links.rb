# frozen_string_literal: true

require 'net/http'
require 'json'

class DropboxLinks
  class Error < StandardError
    attr_reader :retryable

    def initialize(message, retryable: false)
      super(message)
      @retryable = retryable
    end
  end

  def shared_url(path)
    result = api('sharing/create_shared_link_with_settings',
                 path: path, settings: { requested_visibility: 'public' })
    result.fetch('url').sub('https://www.dropbox.com/', 'https://dl.dropboxusercontent.com/')
  rescue Error => e
    raise unless e.message.include?('shared_link_already_exists')

    result = api('sharing/list_shared_links', path: path, direct_only: true)
    result.fetch('links').first.fetch('url').sub('https://www.dropbox.com/', 'https://dl.dropboxusercontent.com/')
  end

  def close
    connection = @connection
    @connection = nil
    connection.finish if connection&.started?
  rescue IOError, SystemCallError, Timeout::Error
    nil
  end

  private

  def connection(uri)
    @connection ||= Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 30)
  end

  def token
    return @token if @token && Time.now < @expires_at

    uri = URI('https://api.dropboxapi.com/oauth2/token')
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(grant_type: 'refresh_token', refresh_token: ENV.fetch('DROPBOX_REFRESH_TOKEN'),
                          client_id: ENV.fetch('DROPBOX_APP_KEY'), client_secret: ENV.fetch('DROPBOX_APP_SECRET'))
    result = perform(uri, request)
    @expires_at = Time.now + result.fetch('expires_in', 14400) - 60
    @token = result.fetch('access_token')
  end

  def api(endpoint, **body)
    uri = URI("https://api.dropboxapi.com/2/#{endpoint}")
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{token}"
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(body)
    perform(uri, request)
  end

  def perform(uri, request)
    response = connection(uri).request(request)
    result = JSON.parse(response.body)
    return result if response.is_a?(Net::HTTPSuccess)

    raise_response_error(response, result)
  rescue IOError, SystemCallError, Timeout::Error => e
    close
    raise Error.new(e.class.name, retryable: true)
  end

  def raise_response_error(response, result)
    summary = result.fetch('error_summary', "HTTP #{response.code}")
    retryable = response.code == '429' || response.code.to_i >= 500 || summary.include?('not_found')
    raise Error.new(summary, retryable: retryable)
  end
end
