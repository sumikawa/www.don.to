#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/image_catalog_environment'
require_relative '../lib/image_catalog_command'

if $PROGRAM_NAME == __FILE__
  $stdout.sync = true
  ImageCatalogEnvironment.load
  begin
    root = File.expand_path('..', __dir__)
    site = YAML.safe_load_file(File.join(root, 'data/site.yml'))
    command = ImageCatalogCommand.new(root: root, site: site)
    exit(command.run?(ARGV) ? 0 : 1)
  rescue StandardError => e
    warn "Image catalog failed: #{e.message}"
    exit 1
  end
end
