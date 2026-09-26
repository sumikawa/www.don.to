# frozen_string_literal: true

require 'set'

class ImageCatalogTarget
  attr_reader :year, :directory, :dirpath, :filenames, :original_files, :cache_directory

  def initialize(article, root:, site:, allow_missing_original: false)
    @year, @directory = article_parts(article, root)
    @dirpath = "#{year}/#{directory}"
    @cache_directory = media_directory(site.fetch('cacherootdir'))
    original = media_directory(site.fetch('imagerootdir'))
    if File.directory?(original)
      set_media_files(original, site)
    elsif allow_missing_original
      @original_files = []
      @filenames = Set.new
    else
      raise ArgumentError, "Original media directory not found: #{original}"
    end
  end

  def pattern
    "diary/#{year}/#{directory}/*.*"
  end

  private

  def media_directory(root)
    File.expand_path(File.join(root, 'diary', year, directory))
  end

  def set_media_files(original, site)
    names = media_names(original).select { |name| cache_names(name.downcase, site).any? }
    @original_files = names.map { |name| File.join(original, name) }
    @filenames = names.flat_map { |name| cache_names(name.downcase, site) }.to_set
  end

  def article_parts(article, root)
    path = File.expand_path(article, article.start_with?('source/') ? root : Dir.pwd)
    relative = path.delete_prefix(File.join(root, 'source/diary/'))
    match = relative.match(%r{\A(\d{4})/([\w-]+)\.html\.md\.erb\z})
    raise ArgumentError, 'Specify an existing source/diary/YYYY/article.html.md.erb' unless match && File.file?(path)

    match.captures
  end

  def media_names(original)
    Dir.children(original).select { |name| File.file?(File.join(original, name)) }
  end

  def cache_names(name, site)
    ext = File.extname(name)
    base = File.basename(name, ext)
    case ext
    when '.jpg', '.heic'
      ["#{base}.#{site.fetch('thumbext')}"]
    when '.png', '.pdf', '.m4a'
      [name]
    when '.mov', '.mp4', '.mts', '.mpg', '.avi'
      ['', 'hd', 'hdtr'].flat_map do |prefix|
        ["#{prefix}#{base}.#{site.fetch('videoext')}", "#{prefix}#{base}.#{site.fetch('thumbext')}"]
      end
    else
      []
    end
  end
end
