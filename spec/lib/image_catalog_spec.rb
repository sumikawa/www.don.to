require 'spec_helper'
require 'tmpdir'
require_relative '../../lib/image_catalog'

RSpec.describe ImageCatalog do
  around do |example|
    Dir.mktmpdir do |root|
      @cache = File.join(root, 'cache')
      @output = File.join(root, 'image')
      FileUtils.mkdir_p(File.join(@cache, 'diary/2026/0909-test'))
      FileUtils.mkdir_p(@output)
      File.write(File.join(@cache, 'diary/2026/0909-test/a.jpg'), 'thumbnail')
      example.run
    end
  end

  let(:client) { instance_double(DropboxLinks) }
  let(:catalog) { described_class.new(cache_root: @cache, output_dir: @output, client: client) }
  before { allow(client).to receive(:close) }

  let(:path) { File.join(@output, '2026.yml') }

  it 'retries an upload that appears later and preserves existing entries' do
    File.write(path, YAML.dump('old' => { 'b.jpg' => 'existing' }))
    calls = 0
    allow(client).to receive(:shared_url).with('/.cache/diary/2026/0909-test/a.jpg') do
      calls += 1
      raise DropboxLinks::Error.new('path/not_found', retryable: true) if calls == 1

      'https://example.com/a.jpg'
    end
    expect(catalog).to receive(:sleep).with(30)
    expect(catalog.sync?('diary/2026/0909-test/*', attempts: 2)).to be true
    expect(YAML.safe_load_file(path)).to eq('old' => { 'b.jpg' => 'existing' },
                                            '0909-test' => { 'a.jpg' => 'https://example.com/a.jpg' })
    expect(client).not_to receive(:shared_url)
    expect(catalog.sync?('diary/2026/0909-test/*')).to be true
  end

  it 'leaves missing uploads unregistered and permits a later run' do
    allow(client).to receive(:shared_url).and_raise(DropboxLinks::Error.new('path/not_found', retryable: true))
    expect(catalog.sync?('diary/2026/0909-test/*', attempts: 1)).to be false
    expect(File.exist?(path)).to be false
    allow(client).to receive(:shared_url).and_return('uploaded')
    expect(catalog.sync?('diary/2026/0909-test/*', attempts: 1)).to be true
  end

  it 'loads the annual catalog once when scanning registered files' do
    File.write(File.join(@cache, 'diary/2026/0909-test/b.jpg'), 'thumbnail')
    File.write(path, YAML.dump('0909-test' => { 'a.jpg' => 'existing-a', 'b.jpg' => 'existing-b' }))
    expect(YAML).to receive(:safe_load_file).with(path).once.and_call_original
    expect(client).not_to receive(:shared_url)
    expect { catalog.sync?('diary/2026/0909-test/*') }.to output(/Found: 2 file.*Image catalog complete./m).to_stdout
  end

  it 'reloads the catalog before saving to preserve another process additions' do
    allow(client).to receive(:shared_url) do
      File.write(path, YAML.dump('other' => { 'b.jpg' => 'concurrent' }))
      'uploaded'
    end
    expect(catalog.sync?('diary/2026/0909-test/*')).to be true
    expect(YAML.safe_load_file(path).fetch('other')).to eq('b.jpg' => 'concurrent')
  end

  it 'saves 31 URLs in two batches' do
    30.times { |i| File.write(File.join(@cache, "diary/2026/0909-test/b#{i}.jpg"), 'thumbnail') }
    allow(client).to receive(:shared_url).and_return('uploaded')
    expect(Tempfile).to receive(:create).twice.and_call_original
    expect(catalog.sync?('diary/2026/0909-test/*')).to be true
    expect(YAML.safe_load_file(path).fetch('0909-test').size).to eq(31)
  end

  it 'flushes acquired URLs and closes the connection when a later request fails' do
    File.write(File.join(@cache, 'diary/2026/0909-test/b.jpg'), 'thumbnail')
    allow(client).to receive(:shared_url).with(/a.jpg/).and_return('uploaded')
    allow(client).to receive(:shared_url).with(/b.jpg/).and_raise(DropboxLinks::Error.new('invalid_access_token'))
    expect(client).to receive(:close)
    expect { catalog.sync?('diary/2026/0909-test/*') }.to raise_error(DropboxLinks::Error)
    expect(YAML.safe_load_file(path).fetch('0909-test')).to eq('a.jpg' => 'uploaded')
  end

  it 'skips the same running selection and releases its lock after completion' do
    duplicate_client = instance_double(DropboxLinks)
    duplicate = described_class.new(cache_root: @cache, output_dir: @output, client: duplicate_client)
    expect(duplicate_client).not_to receive(:shared_url)
    allow(client).to receive(:shared_url) do
      expect { duplicate.sync?('diary/2026/0909-test/*') }.to output(/Already running/).to_stdout
      'uploaded'
    end
    expect(catalog.sync?('diary/2026/0909-test/*')).to be true
    allow(duplicate_client).to receive(:close)
    expect { duplicate.sync?('diary/2026/0909-test/*') }.to output(/Image catalog complete/).to_stdout
  end

  it 'does not retry authentication errors' do
    allow(client).to receive(:shared_url).and_raise(DropboxLinks::Error.new('invalid_access_token'))
    expect(catalog).not_to receive(:sleep)
    expect { catalog.sync?('diary/2026/0909-test/*') }.to raise_error(DropboxLinks::Error)
  end
end
