require 'spec_helper'
require_relative '../../lib/dropbox_links'

RSpec.describe DropboxLinks do
  let(:client) { described_class.new }
  let(:http) { instance_double(Net::HTTP) }

  before do
    allow(client).to receive(:token).and_return('test-token')
    allow(Net::HTTP).to receive(:start).and_return(http)
    allow(http).to receive(:started?).and_return(true)
    allow(http).to receive(:finish)
  end

  def response(type, code, body)
    result = type.new('1.1', code, '')
    allow(result).to receive(:body).and_return(JSON.generate(body))
    result
  end

  it 'creates a public link and preserves its query parameters' do
    expect(http).to receive(:request) do |request|
      expect(JSON.parse(request.body)).to eq('path' => '/.cache/diary/2026/test/a.jpg',
                                             'settings' => { 'requested_visibility' => 'public' })
      response(Net::HTTPOK, '200', 'url' => 'https://www.dropbox.com/scl/fi/a.jpg?rlkey=key&dl=0')
    end
    expect(client.shared_url('/.cache/diary/2026/test/a.jpg'))
      .to eq('https://dl.dropboxusercontent.com/scl/fi/a.jpg?rlkey=key&dl=0')
  end

  it 'retrieves the existing direct shared link after a conflict' do
    expect(http).to receive(:request).ordered
                                     .and_return(response(Net::HTTPConflict, '409', 'error_summary' => 'shared_link_already_exists/'))
    expect(http).to receive(:request).ordered do |request|
      expect(JSON.parse(request.body)).to eq('path' => '/test.jpg', 'direct_only' => true)
      response(Net::HTTPOK, '200', 'links' => [{ 'url' => 'https://www.dropbox.com/test.jpg' }])
    end
    expect(client.shared_url('/test.jpg')).to eq('https://dl.dropboxusercontent.com/test.jpg')
  end

  it 'reuses one connection across requests and closes it explicitly' do
    expect(Net::HTTP).to receive(:start).once.and_return(http)
    allow(http).to receive(:request).and_return(response(Net::HTTPOK, '200', 'url' => 'https://www.dropbox.com/a.jpg'))
    2.times { client.shared_url('/a.jpg') }
    expect(http).to receive(:finish).once
    client.close
    client.close
  end

  it 'discards a broken connection and reconnects on the next attempt' do
    expect(Net::HTTP).to receive(:start).twice.and_return(http)
    expect(http).to receive(:request).ordered.and_raise(EOFError)
    expect(http).to receive(:finish).once
    expect { client.shared_url('/a.jpg') }.to raise_error(DropboxLinks::Error)
    expect(http).to receive(:request).ordered
                                     .and_return(response(Net::HTTPOK, '200', 'url' => 'https://www.dropbox.com/a.jpg'))
    expect(client.shared_url('/a.jpg')).to eq('https://dl.dropboxusercontent.com/a.jpg')
  end

  it 'reports an upload not yet present as retryable' do
    allow(http).to receive(:request)
      .and_return(response(Net::HTTPConflict, '409', 'error_summary' => 'path/not_found/'))
    expect { client.shared_url('/test.jpg') }.to raise_error(DropboxLinks::Error) { |error| expect(error.retryable).to be true }
  end
end
