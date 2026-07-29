#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require_relative '../lib/video'

def print_usage
  puts 'Usage: bundle exec ruby scripts/regenerate_posters.rb YEAR/directory1 YEAR/directory2 ...'
  exit 1
end

print_usage if ARGV.empty?

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

def valid_argument?(arg)
  arg.match?(%r{\A\d{4}/.+\z})
end

def video_files_in(src_dir)
  video_extensions = %w[mp4 mov avi m4v]
  video_glob = File.join(src_dir, "**/*.{#{video_extensions.join(',')}}")
  Dir.glob(video_glob, File::FNM_CASEFOLD).select { |path| File.file?(path) }
end

def probe_prefix(video_path)
  Video.probe(video_path)[:prefix]
rescue StandardError => e
  puts "  Warning: Failed to probe video: #{e.message}. Using default prefix 'hd'."
  'hd'
end

def generate_poster(video_path, dst_dir, thumb_height, thumb_ext)
  puts "Processing #{video_path}..."
  video_ext = File.extname(video_path)
  base_name = File.basename(video_path, video_ext)
  dst_file = "#{probe_prefix(video_path)}#{base_name}.#{thumb_ext}"

  Video.poster(
    src: video_path,
    dst_dir: dst_dir,
    dst_file: dst_file,
    height: thumb_height
  )

  puts "  Generated: #{File.join(dst_dir, dst_file)}"
end

def process_video_files(video_files, dst_dir, thumb_height, thumb_ext)
  success_count = 0
  failure_count = 0

  video_files.each do |video_path|
    generate_poster(video_path, dst_dir, thumb_height, thumb_ext)
    success_count += 1
  rescue StandardError => e
    puts "  Error processing #{video_path}: #{e.message}"
    failure_count += 1
  end

  [success_count, failure_count]
end

def process_argument(arg, imagerootdir, cacherootdir, thumb_height, thumb_ext)
  puts '========================================'
  puts "Processing: #{arg}"

  return [0, 0] unless valid_argument_format?(arg)

  src_dir = File.join(imagerootdir, 'diary', arg)
  dst_dir = File.join(cacherootdir, 'diary', arg)

  return [0, 0] unless source_directory_exists?(src_dir)

  video_files = video_files_in(src_dir)

  if video_files.empty?
    puts "No video files found in #{src_dir}. Skipping."
    return [0, 0]
  end

  # Ensure the destination directory exists
  FileUtils.mkdir_p(dst_dir)

  puts "Found #{video_files.size} video files."
  puts "Regenerating poster images in #{dst_dir} (height: #{thumb_height}, format: #{thumb_ext})..."

  success_count, failure_count = process_video_files(
    video_files,
    dst_dir,
    thumb_height,
    thumb_ext
  )
  puts "Finished #{arg}. Success: #{success_count}, Failure: #{failure_count}"
  [success_count, failure_count]
end

def valid_argument_format?(arg)
  return true if valid_argument?(arg)

  puts 'Error: Argument format must be YEAR/directory (e.g., 2013/0817-camp). Skipping.'
  false
end

def source_directory_exists?(src_dir)
  return true if File.directory?(src_dir)

  puts "Error: Source directory #{src_dir} does not exist. Skipping."
  false
end

ARGV.each do |arg|
  success_count, failure_count = process_argument(
    arg,
    imagerootdir,
    cacherootdir,
    thumb_height,
    thumb_ext
  )
  total_success += success_count
  total_failure += failure_count
end

puts "Done. Total Success: #{total_success}, Total Failure: #{total_failure}"
