#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require_relative '../lib/video'

def print_usage
  puts "Usage: bundle exec ruby scripts/regenerate_posters.rb YEAR/directory1 YEAR/directory2 ..."
  exit 1
end

if ARGV.empty?
  print_usage
end

# Load site configuration for paths, thumbheight, and thumbext
begin
  site_config = YAML.load_file(File.expand_path('../data/site.yml', __dir__))
rescue StandardError => e
  puts "Warning: Failed to load data/site.yml: #{e.message}. Using defaults."
  site_config = {}
end

imagerootdir = File.expand_path(site_config['imagerootdir'] || '~/Dropbox/images')
cacherootdir = File.expand_path(site_config['cacherootdir'] || '~/Dropbox/.cache')

thumb_height = site_config['thumbheight'] || 900
thumb_ext = site_config['thumbext'] || 'jpg'

total_success = 0
total_failure = 0

ARGV.each do |arg|
  puts "========================================"
  puts "Processing: #{arg}"

  if !arg.match?(%r{\A\d{4}/.+\z})
    puts "Error: Argument format must be YEAR/directory (e.g., 2013/0817-camp). Skipping."
    next
  end

  src_dir = File.join(imagerootdir, 'diary', arg)
  dst_dir = File.join(cacherootdir, 'diary', arg)

  if !File.directory?(src_dir)
    puts "Error: Source directory #{src_dir} does not exist. Skipping."
    next
  end

  # Supported video extensions
  video_extensions = %w[mp4 mov avi m4v]
  video_glob = File.join(src_dir, "**/*.{#{video_extensions.join(',')}}")

  # Search recursively but case-insensitively for video files
  video_files = Dir.glob(video_glob, File::FNM_CASEFOLD).select { |f| File.file?(f) }

  if video_files.empty?
    puts "No video files found in #{src_dir}. Skipping."
    next
  end

  # Ensure the destination directory exists
  FileUtils.mkdir_p(dst_dir)

  puts "Found #{video_files.size} video files."
  puts "Regenerating poster images in #{dst_dir} (height: #{thumb_height}, format: #{thumb_ext})..."

  success_count = 0
  failure_count = 0

  video_files.each do |video_path|
    puts "Processing #{video_path}..."
    begin
      video_ext = File.extname(video_path)
      base_name = File.basename(video_path, video_ext)

      # Probe original video to get the prefix (e.g. hd, hdtr)
      begin
        opts = Video.probe(video_path)
        prefix = opts[:prefix]
      rescue StandardError => e
        puts "  Warning: Failed to probe video: #{e.message}. Using default prefix 'hd'."
        prefix = 'hd'
      end

      dst_file = "#{prefix}#{base_name}.#{thumb_ext}"

      # Regenerate poster
      Video.poster(
        src: video_path,
        dst_dir: dst_dir,
        dst_file: dst_file,
        height: thumb_height
      )

      puts "  Generated: #{File.join(dst_dir, dst_file)}"
      success_count += 1
      total_success += 1
    rescue StandardError => e
      puts "  Error processing #{video_path}: #{e.message}"
      failure_count += 1
      total_failure += 1
    end
  end

  puts "Finished #{arg}. Success: #{success_count}, Failure: #{failure_count}"
end

puts "Done. Total Success: #{total_success}, Total Failure: #{total_failure}"
