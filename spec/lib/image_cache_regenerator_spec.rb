require 'spec_helper'
require 'tmpdir'
require 'set'
require_relative '../../lib/image_cache_regenerator'

RSpec.describe ImageCacheRegenerator do
  it 'overwrites a cache file in place and checks the Dropbox file and link' do
    Dir.mktmpdir do |root|
      cache_dir = File.join(root, 'cache/diary/2026/test')
      FileUtils.mkdir_p(cache_dir)
      destination = File.join(cache_dir, 'a.jpg')
      File.write(destination, 'old')
      inode = File.stat(destination).ino
      target = Struct.new(:cache_directory, :dirpath, :original_files, :filenames)
                     .new(cache_dir, '2026/test', [], Set.new(['a.jpg']))
      generator = instance_double(ImageCacheGenerator)
      allow(ImageCacheGenerator).to receive(:new).and_return(generator)
      allow(generator).to receive(:generate) do |staged|
        FileUtils.mkdir_p(staged.cache_directory)
        File.write(File.join(staged.cache_directory, 'a.jpg'), 'new')
      end
      expected_hash = Digest::SHA256.hexdigest(Digest::SHA256.digest('new'))
      client = instance_double(DropboxLinks)
      before = { 'id' => 'id:1', 'content_hash' => 'old' }
      after = { 'id' => 'id:1', 'content_hash' => expected_hash }
      expect(client).to receive(:metadata).twice.and_return(before, after)
      expect(client).to receive(:existing_shared_url).twice.and_return('https://example.com/a')
      expect(client).to receive(:close)
      described_class.new(site: { 'cacherootdir' => File.join(root, 'cache') }, client: client).regenerate(target)
      expect(File.read(destination)).to eq('new')
      expect(File.stat(destination).ino).to eq(inode)
    end
  end

  it 'keeps the existing file when its catalog URL differs from Dropbox' do
    Dir.mktmpdir do |root|
      cache_dir = File.join(root, 'cache/diary/2026/test')
      FileUtils.mkdir_p(cache_dir)
      FileUtils.mkdir_p(File.join(root, 'data/image'))
      destination = File.join(cache_dir, 'a.jpg')
      File.write(destination, 'old')
      File.write(File.join(root, 'data/image/2026.yml'), YAML.dump('test' => { 'a.jpg' => 'expected' }))
      target = Struct.new(:cache_directory, :dirpath, :original_files, :filenames)
                     .new(cache_dir, '2026/test', [], Set.new(['a.jpg']))
      generator = instance_double(ImageCacheGenerator)
      allow(ImageCacheGenerator).to receive(:new).and_return(generator)
      allow(generator).to receive(:generate) do |staged|
        FileUtils.mkdir_p(staged.cache_directory)
        File.write(File.join(staged.cache_directory, 'a.jpg'), 'new')
      end
      client = instance_double(DropboxLinks, metadata: { 'id' => 'id:1' }, existing_shared_url: 'other')
      expect(client).to receive(:close)
      regenerator = described_class.new(site: { 'cacherootdir' => File.join(root, 'cache') }, root: root,
                                        client: client)
      expect { regenerator.regenerate(target) }.to raise_error(/differs from YAML/)
      expect(File.read(destination)).to eq('old')
    end
  end

  it 'refuses to recreate a registered cache file that is missing locally' do
    Dir.mktmpdir do |root|
      cache_dir = File.join(root, 'cache/diary/2026/test')
      FileUtils.mkdir_p(File.join(root, 'data/image'))
      File.write(File.join(root, 'data/image/2026.yml'), YAML.dump('test' => { 'a.jpg' => 'url' }))
      target = Struct.new(:cache_directory, :dirpath, :original_files, :filenames)
                     .new(cache_dir, '2026/test', [], Set.new(['a.jpg']))
      generator = instance_double(ImageCacheGenerator)
      allow(ImageCacheGenerator).to receive(:new).and_return(generator)
      allow(generator).to receive(:generate) do |staged|
        FileUtils.mkdir_p(staged.cache_directory)
        File.write(File.join(staged.cache_directory, 'a.jpg'), 'new')
      end
      client = instance_double(DropboxLinks, close: nil)
      expect(client).not_to receive(:metadata)
      regenerator = described_class.new(site: { 'cacherootdir' => File.join(root, 'cache') }, root: root,
                                        client: client)
      expect { regenerator.regenerate(target) }.to raise_error(/missing locally/)
      expect(File.exist?(File.join(cache_dir, 'a.jpg'))).to be false
    end
  end

  it 'creates an unregistered cache when Dropbox has no file at that path' do
    Dir.mktmpdir do |root|
      cache_dir = File.join(root, 'cache/diary/2026/test')
      target = Struct.new(:cache_directory, :dirpath, :original_files, :filenames)
                     .new(cache_dir, '2026/test', [], Set.new(['a.jpg']))
      generator = instance_double(ImageCacheGenerator)
      allow(ImageCacheGenerator).to receive(:new).and_return(generator)
      allow(generator).to receive(:generate) do |staged|
        FileUtils.mkdir_p(staged.cache_directory)
        File.write(File.join(staged.cache_directory, 'a.jpg'), 'new')
      end
      client = instance_double(DropboxLinks, close: nil)
      allow(client).to receive(:metadata).and_raise(DropboxLinks::Error.new('path/not_found'))
      described_class.new(site: { 'cacherootdir' => File.join(root, 'cache') }, root: root,
                          client: client).regenerate(target)
      expect(File.read(File.join(cache_dir, 'a.jpg'))).to eq('new')
    end
  end
end
