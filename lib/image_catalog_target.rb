# frozen_string_literal: true

require 'set'

class ImageCatalogTarget
  attr_reader :year, :directory, :filenames

  def initialize(article, root:, site:)
    @year, @directory = article_parts(article, root)
    original = File.expand_path(File.join(site.fetch('imagerootdir'), 'diary', year, directory))
    raise ArgumentError, "Original media directory not found: #{original}" unless File.directory?(original)

    @filenames = media_names(original).flat_map { |name| cache_names(name.downcase, site) }.to_set
  end

  def pattern
    "diary/#{year}/#{directory}/*.*"
  end

  private

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
