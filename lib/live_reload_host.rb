# frozen_string_literal: true

require 'rack'

class LiveReloadHost
  LIVE_RELOAD_SCRIPT = %r{(/__rack/livereload\.js\?host=)[^&"']+}.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    response = @app.call(env)
    return response unless html_response?(response[1])

    status, headers, body = response
    content = body_content(body)

    host = Rack::Request.new(env).host
    content.gsub!(LIVE_RELOAD_SCRIPT) do
      match = Regexp.last_match
      "#{match[1]}#{Rack::Utils.escape_html(host)}"
    end
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
