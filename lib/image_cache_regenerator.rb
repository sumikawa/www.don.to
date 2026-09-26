# frozen_string_literal: true

require 'digest'
require 'tmpdir'
require 'fileutils'
require 'yaml'
require_relative 'dropbox_links'
require_relative 'image_cache_generator'
require_relative 'image_cache_path'

class ImageCacheRegenerator
  BLOCK_SIZE = 4 * 1024 * 1024

  def initialize(site:, root: nil, client: DropboxLinks.new)
    @site = site
    @root = root
    @client = client
  end

  def regenerate(target)
    @registered_urls = registered_urls(target)
    Dir.mktmpdir('www-image-cache-') do |root|
      staged = stage_cache(root, target)
      Dir.glob(File.join(staged, '*')).select { |path| File.file?(path) }.sort.each do |source|
        replace_cache(source, target)
      end
    end
  ensure
    @client.close
  end

  private

  def registered_urls(target)
    return {} unless @root

    path = File.join(@root, 'data/image', "#{target.dirpath.split('/').first}.yml")
    return {} unless File.exist?(path)

    (YAML.safe_load_file(path) || {}).fetch(target.dirpath.split('/').last, {})
  end

  def stage_cache(root, target)
    staged = File.join(root, 'diary', target.dirpath)
    stage_target = Struct.new(:cache_directory, :dirpath, :original_files, :filenames)
                         .new(staged, target.dirpath, target.original_files, target.filenames)
    ImageCacheGenerator.new(site: @site).generate(stage_target)
    staged
  end

  def replace_cache(source, target)
    name = File.basename(source)
    destination = File.join(target.cache_directory, name)
    remote_path = "/.cache/diary/#{target.dirpath}/#{name}"
    if File.exist?(destination)
      replace_existing(source, destination, remote_path)
    else
      raise "Registered cache is missing locally: #{destination}" if @registered_urls.key?(name)

      ensure_remote_absent(remote_path)
      FileUtils.mkdir_p(target.cache_directory)
      FileUtils.copy_file(source, destination)
      puts "Created cache: #{display_path(destination)}"
    end
  end

  def ensure_remote_absent(path)
    @client.metadata(path)
    raise "Dropbox file exists but local cache is missing: #{path}"
  rescue DropboxLinks::Error => e
    raise unless e.message.include?('path/not_found')
  end

  def replace_existing(source, destination, remote_path)
    before = @client.metadata(remote_path)
    link = @client.existing_shared_url(remote_path)
    expected_link = @registered_urls[File.basename(destination)]
    raise "Dropbox shared URL differs from YAML: #{remote_path}" if expected_link && link != expected_link

    expected_hash = content_hash(source)
    return if before['content_hash'] == expected_hash && content_hash(destination) == expected_hash

    overwrite_in_place(source, destination)
    verify_remote(remote_path, before.fetch('id'), link, expected_hash)
    puts "Regenerated cache: #{display_path(destination)}"
  end

  def display_path(path)
    ImageCachePath.display(path, cache_root: @site.fetch('cacherootdir'))
  end

  def overwrite_in_place(source, destination)
    File.open(destination, File::WRONLY | File::TRUNC) do |output|
      File.open(source, 'rb') { |input| IO.copy_stream(input, output) }
      output.flush
      output.fsync
    end
  end

  def verify_remote(path, original_id, original_link, expected_hash)
    synced = false
    61.times do |attempt|
      after = @client.metadata(path)
      raise "Dropbox file ID changed: #{path}" unless after.fetch('id') == original_id
      raise "Dropbox shared URL changed: #{path}" unless @client.existing_shared_url(path) == original_link

      if after['content_hash'] == expected_hash
        synced = true
        break
      end

      break if attempt == 60

      sleep 30
    end
    raise "Dropbox update did not complete: #{path}" unless synced
  end

  def content_hash(path)
    hash = Digest::SHA256.new
    File.open(path, 'rb') do |file|
      while (block = file.read(BLOCK_SIZE))
        hash.update(Digest::SHA256.digest(block))
      end
    end
    hash.hexdigest
  end
end
