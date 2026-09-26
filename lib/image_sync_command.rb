# frozen_string_literal: true

require 'yaml'
require_relative 'image_sync_preview'

module ImageSyncCommand
  private

  def run_image_command?(arguments, verbose:)
    mode = arguments.first
    options = arguments.drop(1)
    dry_run = options.delete('--dry-run') == '--dry-run'
    raise ArgumentError, self.class::USAGE if options.size != 1 || (mode == 'cache' && dry_run)

    validate_original_root
    run_articles?(mode, image_articles(options.first), selection: options.first, dry_run: dry_run, verbose: verbose)
  end

  def run_articles?(mode, articles, selection:, dry_run:, verbose:)
    strict_video = !selection.match?(/\A\d{4}\z/)
    return preview_articles?(mode, articles, strict_video: strict_video) if dry_run

    process_articles?(mode, articles, selection: selection, verbose: verbose, strict_video: strict_video)
  end

  def preview_articles?(mode, articles, strict_video:)
    results = articles.map do |article|
      process_image_article(mode, article, dry_run: true, strict_video: strict_video)
    end
    puts 'No changes.' if results.all? && results.sum.zero?
    results.all?
  end

  def process_articles?(mode, articles, selection:, verbose:, strict_video:)
    action = mode == 'cache' ? 'Regenerating cache' : 'Syncing'
    puts "#{action}: #{selection} (#{articles.size} articles)"
    results = articles.map do |article|
      ImageCommandOutput.with_details(verbose) do
        process_image_article(mode, article, dry_run: false, strict_video: strict_video)
      end
    end
    puts "Completed: #{results.count(true)}/#{articles.size} articles"
    results.all?
  end

  def validate_original_root
    root = File.expand_path(@site.fetch('imagerootdir'))
    diary_root = File.join(root, 'diary')
    raise ArgumentError, "Original media root not found: #{diary_root}" unless File.directory?(diary_root)
  end

  def image_articles(selection)
    if selection.match?(/\A\d{4}\z/)
      directory = File.join(@root, 'source/diary', selection)
      raise ArgumentError, "Article year directory not found: #{directory}" unless File.directory?(directory)

      Dir.glob(File.join(directory, '*.html.md.erb')).sort
    else
      [File.expand_path(selection, @root)]
    end
  end

  def process_image_article(mode, article, dry_run:, strict_video:)
    target = ImageCatalogTarget.new(article, root: @root, site: @site, allow_missing_original: true)
    return ImageSyncPreview.new(root: @root, site: @site, strict_video: strict_video).show(target) if dry_run

    if mode == 'cache'
      ImageCacheRegenerator.new(site: @site, root: @root).regenerate(target)
    else
      ImageCacheGenerator.new(site: @site, strict_video: strict_video).generate(target)
      return catalog.sync?(target.pattern, target: target)
    end
    true
  rescue StandardError => e
    warn "Image #{mode} failed (#{article}): #{e.message}"
    false
  end
end
