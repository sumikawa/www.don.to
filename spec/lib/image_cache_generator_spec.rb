require 'spec_helper'
require 'tmpdir'
require 'set'
require_relative '../../lib/image_cache_generator'

RSpec.describe ImageCacheGenerator do
  it 'does not create a cache directory for an article without media' do
    Dir.mktmpdir do |root|
      destination = File.join(root, 'cache/diary/2026/empty')
      target = instance_double('target', original_files: [], cache_directory: destination)
      described_class.new(site: { 'cacherootdir' => File.join(root, 'cache') }).generate(target)
      expect(File.exist?(destination)).to be false
    end
  end

  it 'copies missing audio cache files without replacing existing files' do
    Dir.mktmpdir do |root|
      source = File.join(root, 'source.m4a')
      destination = File.join(root, 'cache/diary/2026/test')
      FileUtils.mkdir_p(destination)
      File.write(source, 'audio')
      target = instance_double('target', original_files: [source], cache_directory: destination,
                                         dirpath: '2026/test', filenames: Set.new(['source.m4a']))
      described_class.new(site: { 'cacherootdir' => destination, 'thumbext' => 'jpg', 'thumbheight' => 900,
                                  'videoext' => 'mp4', 'vcodec' => 'mp4', 'acodec' => 'aac' }).generate(target)
      expect(File.read(File.join(destination, 'source.m4a'))).to eq('audio')
    end
  end

  it 'does not overwrite an existing cache file' do
    Dir.mktmpdir do |root|
      source = File.join(root, 'source.m4a')
      destination = File.join(root, 'cache/diary/2026/test')
      FileUtils.mkdir_p(destination)
      File.write(source, 'new')
      File.write(File.join(destination, 'source.m4a'), 'old')
      target = instance_double('target', original_files: [source], cache_directory: destination,
                                         dirpath: '2026/test', filenames: Set.new(['source.m4a']))
      described_class.new(site: { 'cacherootdir' => destination, 'thumbext' => 'jpg', 'thumbheight' => 900,
                                  'videoext' => 'mp4', 'vcodec' => 'mp4', 'acodec' => 'aac' }).generate(target)
      expect(File.read(File.join(destination, 'source.m4a'))).to eq('old')
    end
  end
end
