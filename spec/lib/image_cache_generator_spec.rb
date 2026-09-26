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

  it 'skips video probing for a year sync when any derived file exists' do
    Dir.mktmpdir do |root|
      original = File.join(root, 'clip.mov')
      destination = File.join(root, 'cache/diary/2025/test')
      FileUtils.mkdir_p(destination)
      File.write(original, 'video')
      File.write(File.join(destination, 'hdclip.jpg'), 'poster')
      target = instance_double('target', original_files: [original], cache_directory: destination,
                                         dirpath: '2025/test')
      site = { 'cacherootdir' => File.join(root, 'cache'), 'videoext' => 'mp4', 'thumbext' => 'jpg' }
      expect(Video).not_to receive(:probe)
      described_class.new(site: site, strict_video: false).generate(target)
    end
  end

  it 'probes a video for an article sync even when a derived file exists' do
    Dir.mktmpdir do |root|
      original = File.join(root, 'clip.mov')
      destination = File.join(root, 'cache/diary/2025/test')
      FileUtils.mkdir_p(destination)
      File.write(original, 'video')
      File.write(File.join(destination, 'hdclip.jpg'), 'poster')
      target = instance_double('target', original_files: [original], cache_directory: destination,
                                         dirpath: '2025/test')
      site = { 'cacherootdir' => File.join(root, 'cache'), 'videoext' => 'mp4', 'thumbext' => 'jpg' }
      generator = described_class.new(site: site, strict_video: true)
      opts = { prefix: 'hd' }
      expect(Video).to receive(:probe).with(original).and_return(opts)
      expect(generator).to receive(:convert_video_and_create_poster).with(include(path: original), opts, '2025/test')
      generator.generate(target)
    end
  end
end
