# frozen_string_literal: true

require 'yaml'
require 'set'
require_relative 'video'
require_relative 'image_cache_path'
require_relative 'image_video_cache'

class ImageSyncPreview
  def initialize(root:, site:, strict_video: false)
    @root = root
    @site = site
    @strict_video = strict_video
  end

  def show(target)
    actions = planned_actions(target)
    return 0 if actions.empty?

    puts "Article: #{target.dirpath}"
    actions.each { |action| puts "  #{action}" }
    actions.size
  end

  private

  def planned_actions(target)
    paths = Dir.glob(File.join(target.cache_directory, '*.*')).select { |path| File.file?(path) }
    missing = missing_cache_names(target, paths)
    additions = new_cache_actions(target, paths, missing)
    additions + cache_deletions(paths, target) + catalog_changes(paths, missing, catalog_entries(target), target)
  end

  def new_cache_actions(target, paths, missing)
    actions = missing.map { |name| "Generate cache: #{cache_path(File.join(target.cache_directory, name))}" }
    actions + video_actions(target, paths)
  end

  def catalog_entries(target)
    path = File.join(@root, 'data/image', "#{target.year}.yml")
    return {} unless File.exist?(path)

    (YAML.safe_load_file(path) || {}).fetch(target.directory, {})
  end

  def cache_deletions(paths, target)
    paths.reject { |path| target.filenames.include?(File.basename(path)) }
         .map { |path| "Delete cache: #{cache_path(path)}" }
  end

  def cache_path(path)
    ImageCachePath.display(path, cache_root: @site.fetch('cacherootdir'))
  end

  def missing_cache_names(target, paths)
    existing = paths.to_set { |path| File.basename(path) }
    target.original_files.flat_map { |path| output_names(path) }.uniq.reject { |name| existing.include?(name) }
  end

  def output_names(path)
    name = File.basename(path).downcase
    ext = File.extname(name)
    base = File.basename(name, ext)
    case ext
    when '.jpg', '.heic' then ["#{base}.#{@site.fetch('thumbext')}"]
    when '.png', '.pdf', '.m4a' then [name]
    when '.mov', '.mp4', '.mts', '.mpg', '.avi'
      return [] unless @strict_video

      prefix = Video.probe(path).fetch(:prefix)
      ["#{prefix}#{base}.#{@site.fetch('videoext')}", "#{prefix}#{base}.#{@site.fetch('thumbext')}"]
    end
  end

  def video_actions(target, paths)
    return [] if @strict_video

    existing = paths.to_set { |path| File.basename(path) }
    target.original_files.filter_map do |path|
      next unless video?(path)
      next if video_cache_present?(path, existing)

      source = ImageCachePath.display(path, cache_root: @site.fetch('imagerootdir'))
      "Generate video cache if missing: #{source}"
    end
  end

  def video?(path)
    %w[.mov .mp4 .mts .mpg .avi].include?(File.extname(path).downcase)
  end

  def video_cache_present?(path, existing)
    ImageVideoCache.names(path, @site).any? { |name| existing.include?(name) }
  end

  def catalog_changes(paths, missing, entries, target)
    removals = catalog_removals(entries, target)
    removals + catalog_additions(paths, missing, entries, target)
  end

  def catalog_removals(entries, target)
    entries.keys.reject { |name| target.filenames.include?(name) }
           .map { |name| "Remove YAML: #{name}" }
  end

  def catalog_additions(paths, missing, entries, target)
    names = paths.map { |path| File.basename(path) } + missing
    names.uniq.select { |name| target.filenames.include?(name) && !entries.key?(name) }
         .map { |name| "Register URL if missing: #{name}" }
  end
end
