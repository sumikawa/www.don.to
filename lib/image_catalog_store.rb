# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'tempfile'
require 'tmpdir'
require 'digest'

class ImageCatalogStore
  def initialize(output_dir)
    @output_dir = output_dir
    @catalogs = {}
    @pending = {}
    @count = 0
  end

  def registered?(year, directory, filename)
    catalog = (@catalogs[year] ||= read_catalog(path_for(year)))
    catalog.dig(directory, filename)
  end

  def add(year, directory, filename, url)
    ((@catalogs[year] ||= {})[directory] ||= {})[filename] = url
    ((@pending[year] ||= {})[directory] ||= {})[filename] = url
    @count += 1
    flush if @count >= 30
  end

  def flush
    @pending.each_key do |year|
      save(year, @pending.fetch(year))
      @pending.delete(year)
    end
    @count = 0
  end

  private

  def path_for(year)
    File.join(@output_dir, "#{year}.yml")
  end

  def read_catalog(path)
    File.exist?(path) ? (YAML.safe_load_file(path) || {}) : {}
  end

  def save(year, additions)
    FileUtils.mkdir_p(@output_dir)
    path = path_for(year)
    lock_path = File.join(Dir.tmpdir, "www-image-#{Digest::SHA256.hexdigest(path)}.lock")
    File.open(lock_path, 'w') do |lock|
      lock.flock(File::LOCK_EX)
      catalog = read_catalog(path)
      additions.each { |directory, entries| (catalog[directory] ||= {}).merge!(entries) { |_key, old, _new| old } }
      write_catalog(path, catalog)
      @catalogs[year] = catalog
    end
    puts "Saved: #{path}"
  end

  def write_catalog(path, catalog)
    Tempfile.create(['.image-', '.yml'], @output_dir) do |file|
      file.write(YAML.dump(catalog))
      file.close
      File.rename(file.path, path)
    end
  end
end
