# frozen_string_literal: true

require_relative 'image_catalog_store'
require_relative 'dropbox_links'

class ImageCatalog
  def initialize(cache_root:, output_dir:, client: DropboxLinks.new)
    @cache_root = File.expand_path(cache_root)
    @output_dir = File.expand_path(output_dir)
    @client = client
  end

  def sync?(pattern, attempts: 61, interval: 30, target: nil)
    key = Digest::SHA256.hexdigest([@cache_root, @output_dir, pattern].join("\0"))
    lock_path = File.join(Dir.tmpdir, "www-image-job-#{key}.lock")
    File.open(lock_path, 'w') do |lock|
      unless lock.flock(File::LOCK_EX | File::LOCK_NB)
        puts "Already running: #{pattern}"
        return true
      end
      run_sync(pattern, attempts: attempts, interval: interval, target: target)
    end
  end

  private

  def run_sync(pattern, attempts:, interval:, target:)
    @store = ImageCatalogStore.new(@output_dir)
    pending = scan_target(pattern, target)
    attempts.times do |attempt|
      pending = register_pending(pending)
      if pending.empty?
        puts 'Image catalog complete.'
        return true
      end
      break if attempt == attempts - 1

      puts "Waiting #{interval}s: #{pending.length} pending file(s), next attempt #{attempt + 2}/#{attempts}"
      sleep interval
    end
    warn "Dropbox upload pending: #{pending.length} file(s). Run scripts/gen_image.rb again."
    false
  ensure
    begin
      @store.flush
    ensure
      @client.close
    end
  end

  def scan_target(pattern, target)
    return scan(pattern) unless target

    @store.prune(target.year, target.directory, target.filenames)
    scan(pattern).select { |path| target.filenames.include?(File.basename(path)) }
  end

  def register_pending(pending)
    remaining = pending.reject { |path| register(path) }
    @store.flush
    remaining
  end

  def scan(pattern)
    puts "Scanning: #{@cache_root}/#{pattern}"
    files = Dir.glob(File.join(@cache_root, pattern)).select { |path| File.file?(path) }
    puts "Found: #{files.length} file(s)"
    files
  end

  def register(path)
    relative = path.delete_prefix("#{@cache_root}/")
    parts = relative.split('/')
    return true unless valid_parts?(parts)

    _category, year, directory, filename = parts
    return true if @store.registered?(year, directory, filename)

    puts "Requesting Dropbox link: #{relative}"
    url = @client.shared_url("/.cache/#{relative}")
    @store.add(year, directory, filename, url)
    puts "Fetched: #{year}/#{directory}/#{filename}"
    true
  rescue DropboxLinks::Error => e
    raise unless e.retryable

    warn "Dropbox pending: #{relative} (#{e.message})"
    false
  end

  def valid_parts?(parts)
    parts.length == 4 && parts[1].match?(/\A\d{4}\z/)
  end
end
