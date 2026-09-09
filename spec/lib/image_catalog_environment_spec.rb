require 'spec_helper'
require 'tmpdir'
require_relative '../../lib/image_catalog_environment'

RSpec.describe ImageCatalogEnvironment do
  around do |example|
    original = ENV.fetch('DROPBOX_REFRESH_TOKEN', nil)
    ENV.delete('DROPBOX_REFRESH_TOKEN')
    Dir.mktmpdir do |root|
      @root = root
      @data = File.join(root, 'repo/data')
      FileUtils.mkdir_p(@data)
      example.run
    end
  ensure
    original.nil? ? ENV.delete('DROPBOX_REFRESH_TOKEN') : ENV['DROPBOX_REFRESH_TOKEN'] = original
  end

  before { allow(Dir).to receive(:home).and_return(@root) }

  it 'loads credentials from the home directory' do
    File.write(File.join(@root, '.env'), "DROPBOX_REFRESH_TOKEN=ancestor-test\n")
    described_class.load
    expect(ENV.fetch('DROPBOX_REFRESH_TOKEN')).to eq('ancestor-test')
  end

  it 'ignores a dotenv file in the working directory' do
    File.write(File.join(@root, '.env'), "DROPBOX_REFRESH_TOKEN=ancestor-test\n")
    File.write(File.join(@data, '.env'), "DROPBOX_REFRESH_TOKEN=local-test\n")
    Dir.chdir(@data) { described_class.load }
    expect(ENV.fetch('DROPBOX_REFRESH_TOKEN')).to eq('ancestor-test')
  end

  it 'preserves credentials already set in the environment' do
    File.write(File.join(@root, '.env'), "DROPBOX_REFRESH_TOKEN=home-test\n")
    ENV['DROPBOX_REFRESH_TOKEN'] = 'environment-test'
    described_class.load
    expect(ENV.fetch('DROPBOX_REFRESH_TOKEN')).to eq('environment-test')
  end
end
