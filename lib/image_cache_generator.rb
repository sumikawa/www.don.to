# frozen_string_literal: true

require 'fileutils'
require_relative '../helpers/diary_index_helpers'

class ImageCacheGenerator
  include DiaryIndexHelpers

  def initialize(site:)
    site_struct = Struct.new(*site.keys.map(&:to_sym), keyword_init: true)
    @data = Struct.new(:site).new(site_struct.new(**site.transform_keys(&:to_sym)))
  end

  def generate(target)
    @data.site.cacherootdir = File.expand_path('../../..', target.cache_directory)
    FileUtils.mkdir_p(target.cache_directory)
    target.original_files.each { |path| generate_file(path, target) }
  end

  private

  attr_reader :data

  def localhost?
    true
  end

  def generate_file(path, target)
    name = File.basename(path).downcase
    ext = File.extname(name).delete_prefix('.')
    file_info = { path: path, name: name, ext: ext, base: File.basename(name, ".#{ext}") }
    case ext
    when 'jpg', 'heic', 'png', 'pdf'
      generate_image(file_info, target)
    when 'm4a'
      generate_audio(file_info, target)
    when 'mov', 'mp4', 'mts', 'mpg', 'avi'
      generate_video(file_info, target)
    end
  end

  def generate_image(file_info, target)
    return if cache_exists?(target, file_info)

    send(:cache_image, file_info, target.dirpath)
  end

  def generate_audio(file_info, target)
    return if cache_exists?(target, file_info)

    send(:cache_image, file_info, target.dirpath)
  end

  def generate_video(file_info, target)
    opts = Video.probe(file_info[:path])
    send(:convert_video_and_create_poster, file_info, opts, target.dirpath)
  end

  def cache_exists?(target, file_info)
    target.filenames.include?(file_info[:name]) && File.exist?(File.join(target.cache_directory, file_info[:name]))
  end
end
