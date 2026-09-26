# frozen_string_literal: true

require_relative 'image_catalog'
require_relative 'image_catalog_target'
require_relative 'image_cache_generator'
require_relative 'image_sync_command'
require_relative 'image_cache_regenerator'
require_relative 'image_command_output'

class ImageCatalogCommand
  include ImageSyncCommand

  USAGE = 'Usage: gen_image.rb sync YYYY|ARTICLE [--dry-run] [-v] | cache YYYY|ARTICLE [-v] | [YYYY[/MMDD-title]] [-v]'
  HELP = <<~TEXT
    #{USAGE}

    Options:
      sync YYYY|ARTICLE        Generate cache files, remove stale files, and update YAML.
      cache YYYY|ARTICLE       Regenerate cache files while preserving shared links.
      --dry-run                Preview sync without changing files or contacting Dropbox.
      -v                       Show detailed progress.
      -h, --help                Show this help.
  TEXT

  def initialize(root:, site:)
    @root = root
    @site = site
  end

  def run?(arguments)
    arguments = arguments.dup
    verbose = arguments.delete('-v') == '-v'
    return true if print_help?(arguments)
    return run_image_command?(arguments, verbose: verbose) if %w[sync cache].include?(arguments.first)

    selection = arguments.first
    validate_selection(arguments, selection)

    pattern = selection&.include?('/') ? "diary/#{selection}/*.*" : "*/#{selection || '*'}/**/*.*"
    puts "Registering URLs: #{selection || 'all'}"
    result = ImageCommandOutput.with_details(verbose) { catalog.sync?(pattern) }
    puts(result ? 'URL registration complete.' : 'URL registration incomplete.')
    result
  end

  private

  def print_help?(arguments)
    return false unless %w[-h --help].include?(arguments.first)

    puts HELP
    true
  end

  def catalog
    ImageCatalog.new(cache_root: @site.fetch('cacherootdir'), output_dir: File.join(@root, 'data/image'))
  end

  def validate_selection(arguments, selection)
    valid = selection.nil? || selection.match?(%r{\A\d{4}(?:/[\w-]+)?\z})
    raise ArgumentError, USAGE unless arguments.size <= 1 && valid
  end
end
