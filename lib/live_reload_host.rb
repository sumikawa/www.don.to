# frozen_string_literal: true

require 'rack'

class LiveReloadHost
  LIVE_RELOAD_SCRIPT = %r{(/__rack/livereload\.js\?host=)[^&"']+}.freeze
  LIVE_RELOAD_SCHEME = /(RACK_LIVERELOAD_SCHEME = ")[^"]+(")/.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    response = @app.call(env)
    return response unless html_response?(response[1])

    status, headers, body = response
    content = body_content(body)

    host = Rack::Request.new(env).host
    scheme = host == 'localhost' ? 'ws' : 'wss'
    content.gsub!(LIVE_RELOAD_SCRIPT) do
      match = Regexp.last_match
      "#{match[1]}#{Rack::Utils.escape_html(host)}"
    end
    content.gsub!(LIVE_RELOAD_SCHEME, "\\1#{scheme}\\2")
    headers['Content-Length'] = content.bytesize.to_s

    [status, headers, [content]]
  end

  private

  def body_content(body)
    content = body.each_with_object(+'') { |chunk, result| result << chunk.to_s }
    body.close if body.respond_to?(:close)
    content
  end

  def html_response?(headers)
    headers['Content-Type'].to_s.start_with?('text/html')
  end
end
