#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/image_catalog_environment'
require_relative '../lib/image_catalog'

if $PROGRAM_NAME == __FILE__
  $stdout.sync = true
  ImageCatalogEnvironment.load
  selection = ARGV.shift
  unless ARGV.empty? && (selection.nil? || selection.match?(%r{\A\d{4}(?:/[\w-]+)?\z}))
    warn 'Usage: gen_image.rb [YYYY[/MMDD-title]]'
    exit 1
  end
  site = YAML.safe_load_file(File.expand_path('../data/site.yml', __dir__))
  pattern = selection&.include?('/') ? "diary/#{selection}/*.*" : "*/#{selection || '*'}/**/*.*"
  begin
    catalog = ImageCatalog.new(cache_root: site.fetch('cacherootdir'),
                               output_dir: File.expand_path('../data/image', __dir__))
    exit(catalog.sync?(pattern) ? 0 : 1)
  rescue StandardError => e
    warn "Image catalog failed: #{e.message}"
    exit 1
  end
end
