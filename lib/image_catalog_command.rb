# frozen_string_literal: true

require_relative 'image_catalog'
require_relative 'image_catalog_target'

class ImageCatalogCommand
  USAGE = 'Usage: gen_image.rb [YYYY[/MMDD-title]] | -u ARTICLE [ARTICLE ...] | -p YYYY'

  def initialize(root:, site:)
    @root = root
    @site = site
  end

  def run?(arguments)
    verbose = arguments.include?('-v')
    arguments = arguments.reject { |argument| argument == '-v' }
    return update?(arguments.drop(1)) if arguments.first == '-u'
    return print_cache_only_year?(arguments.drop(1), verbose: verbose) if arguments.first == '-p'

    selection = arguments.first
    validate_selection(arguments, selection)

    pattern = selection&.include?('/') ? "diary/#{selection}/*.*" : "*/#{selection || '*'}/**/*.*"
    catalog.sync?(pattern)
  end

  private

  def catalog
    ImageCatalog.new(cache_root: @site.fetch('cacherootdir'), output_dir: File.join(@root, 'data/image'))
  end

  def validate_selection(arguments, selection)
    valid = selection.nil? || selection.match?(%r{\A\d{4}(?:/[\w-]+)?\z})
    raise ArgumentError, USAGE unless arguments.size <= 1 && valid
  end

  def update?(articles)
    raise ArgumentError, USAGE if articles.empty?

    results = articles.flat_map { |article| expand(article) }.uniq.map do |article|
      update_article(article)
    end
    results.all?
  end

  def print_cache_only_year?(arguments, verbose: false)
    year = arguments.first
    raise ArgumentError, USAGE unless arguments.size == 1 && year.match?(/\A\d{4}\z/)

    articles = Dir.glob(File.join(@root, "source/diary/#{year}/*.html.md.erb"))
    results = articles.map do |article|
      print_cache_only_article(article, verbose: verbose)
    end
    results.all?
  end

  def expand(article)
    path = File.expand_path(article, article.start_with?('source/') ? @root : Dir.pwd)
    matches = Dir.glob(path)
    matches.empty? ? [path] : matches
  end

  def update_article(article)
    puts "Updating: #{article}"
    target = ImageCatalogTarget.new(article, root: @root, site: @site)
    catalog.sync?(target.pattern, target: target)
  rescue StandardError => e
    warn "Image catalog failed (#{article}): #{e.message}"
    false
  end

  def print_cache_only_article(article, verbose:)
    puts "Checking: #{article}" if verbose
    target = ImageCatalogTarget.new(article, root: @root, site: @site, allow_missing_original: true)
    catalog.cache_only(target)
    true
  rescue StandardError => e
    warn "Image catalog failed (#{article}): #{e.message}"
    false
  end
end
