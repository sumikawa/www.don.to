require 'spec_helper'
require 'tmpdir'
require 'set'
require_relative '../../lib/image_sync_preview'

RSpec.describe ImageSyncPreview do
  it 'lists only missing HEIC and JPEG cache outputs' do
    Dir.mktmpdir do |root|
      originals = File.join(root, 'images/diary/2026/test')
      cache = File.join(root, 'cache/diary/2026/test')
      FileUtils.mkdir_p(originals)
      FileUtils.mkdir_p(cache)
      %w[existing.heic missing.jpg].each { |name| File.write(File.join(originals, name), 'image') }
      File.write(File.join(cache, 'existing.jpg'), 'cached')
      target = Struct.new(:cache_directory, :dirpath, :original_files, :year, :directory, :filenames)
                     .new(cache, '2026/test', Dir.glob(File.join(originals, '*')), '2026', 'test',
                          Set.new(%w[existing.jpg missing.jpg]))
      preview = described_class.new(root: root, site: { 'thumbext' => 'jpg', 'cacherootdir' => File.join(root, 'cache') })
      expect { preview.show(target) }.to output(%r{Generate cache: cache/diary/2026/test/missing.jpg}).to_stdout
      expect { preview.show(target) }.not_to output(/Generate cache: .*existing.jpg/).to_stdout
      File.write(File.join(cache, 'missing.jpg'), 'cached')
      FileUtils.mkdir_p(File.join(root, 'data/image'))
      entries = { 'existing.jpg' => 'url', 'missing.jpg' => 'url' }
      File.write(File.join(root, 'data/image/2026.yml'), YAML.dump('test' => entries))
      expect { expect(preview.show(target)).to eq(0) }.not_to output.to_stdout
    end
  end

  it 'reports missing video cache without probing the video' do
    Dir.mktmpdir do |root|
      originals = File.join(root, 'images/diary/2025/test')
      cache = File.join(root, 'cache/diary/2025/test')
      FileUtils.mkdir_p(originals)
      FileUtils.mkdir_p(cache)
      video = File.join(originals, 'clip.mov')
      File.write(video, 'video')
      target = Struct.new(:cache_directory, :dirpath, :original_files, :year, :directory, :filenames)
                     .new(cache, '2025/test', [video], '2025', 'test', Set.new(%w[hdclip.mp4 hdclip.jpg]))
      site = { 'cacherootdir' => File.join(root, 'cache'), 'imagerootdir' => File.join(root, 'images'),
               'videoext' => 'mp4', 'thumbext' => 'jpg' }
      preview = described_class.new(root: root, site: site)
      expect { preview.show(target) }.to output(%r{Generate video cache if missing: images/diary/2025/test/clip.mov})
        .to_stdout
      File.write(File.join(cache, 'hdclip.mp4'), 'video')
      FileUtils.mkdir_p(File.join(root, 'data/image'))
      entries = { 'hdclip.mp4' => 'url' }
      File.write(File.join(root, 'data/image/2025.yml'), YAML.dump('test' => entries))
      expect { expect(preview.show(target)).to eq(0) }.not_to output.to_stdout
      File.delete(File.join(cache, 'hdclip.mp4'))
      File.write(File.join(cache, 'hdclip.jpg'), 'poster')
      File.write(File.join(root, 'data/image/2025.yml'), YAML.dump('test' => { 'hdclip.jpg' => 'url' }))
      expect { expect(preview.show(target)).to eq(0) }.not_to output.to_stdout
    end
  end

  it 'checks the exact video variant for an article preview' do
    Dir.mktmpdir do |root|
      originals = File.join(root, 'images/diary/2025/test')
      cache = File.join(root, 'cache/diary/2025/test')
      FileUtils.mkdir_p(originals)
      FileUtils.mkdir_p(cache)
      video = File.join(originals, 'clip.mov')
      File.write(video, 'video')
      File.write(File.join(cache, 'hdclip.mp4'), 'converted')
      target = Struct.new(:cache_directory, :dirpath, :original_files, :year, :directory, :filenames)
                     .new(cache, '2025/test', [video], '2025', 'test', Set.new(%w[hdclip.mp4 hdclip.jpg]))
      site = { 'cacherootdir' => File.join(root, 'cache'), 'imagerootdir' => File.join(root, 'images'),
               'videoext' => 'mp4', 'thumbext' => 'jpg' }
      expect(Video).to receive(:probe).with(video).and_return(prefix: 'hd')
      preview = described_class.new(root: root, site: site, strict_video: true)
      expect { preview.show(target) }.to output(%r{Generate cache: cache/diary/2025/test/hdclip.jpg}).to_stdout
    end
  end
end
