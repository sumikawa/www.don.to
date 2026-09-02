require 'rack'
require_relative '../../lib/live_reload_host'

RSpec.describe LiveReloadHost do
  it 'uses the request host in the injected LiveReload script' do
    app = described_class.new(lambda { |_env|
      [200, { 'Content-Type' => 'text/html', 'Content-Length' => '0' },
       ['<head><script>RACK_LIVERELOAD_SCHEME = "ws";</script><script src="/__rack/livereload.js?host=old.example&amp;port=35729"></script></head>']]
    })

    status, headers, body = app.call(
      Rack::MockRequest.env_for('http://actual.example/page')
    )

    expect(status).to eq(200)
    expect(body.join).to include('host=actual.example&amp;port=35729')
    expect(body.join).to include('RACK_LIVERELOAD_SCHEME = "wss"')
    expect(headers['Content-Length']).to eq(body.join.bytesize.to_s)
  end

  it 'keeps ws for localhost' do
    app = described_class.new(lambda { |_env|
      [200, { 'Content-Type' => 'text/html' },
       ['<head>RACK_LIVERELOAD_SCHEME = "ws";</head>']]
    })

    _status, _headers, body = app.call(Rack::MockRequest.env_for('http://localhost/page'))

    expect(body.join).to include('RACK_LIVERELOAD_SCHEME = "ws"')
  end

  it 'does not change non-HTML responses' do
    body = ['host=old.example']
    app = described_class.new(->(_env) { [200, { 'Content-Type' => 'application/javascript' }, body] })

    _status, headers, returned_body = app.call(Rack::MockRequest.env_for('http://actual.example/page'))

    expect(returned_body).to equal(body)
    expect(headers).not_to have_key('Content-Length')
  end
end
