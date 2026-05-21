# frozen_string_literal: true

require 'mini_exiftool'
require 'rmagick'
require 'fileutils'
require_relative '../lib/video'
require_relative 'diary_media_helpers'

module DiaryIndexHelpers
  def gen_index(dirpath)
    now = Time.now
    files_data = Dir.glob(File.expand_path("#{data.site.imagerootdir}/diary/#{dirpath}/*")).sort.map do |file_path|
      process_index_file(file_path, dirpath, now)
    end.compact

    sorted_files_data = files_data.sort_by { |data| data[0] }
    body = build_index_body(sorted_files_data)

    File.open("source/diary/#{dirpath}.html.md.erb", 'w') do |file|
      file.puts(body)
    end
  end

  private

  def build_index_body(sorted_files_data)
    body = ['---', 'draft: true', 'title: ', '---']
    body.concat(sorted_files_data.map { |data| data[1] })
    body.join("\n")
  end

  def process_index_file(file_path, dirpath, now)
    file_name = File.basename(file_path).downcase
    ext = File.extname(file_name)
    base = File.basename(file_name, ext)
    file_info = { path: file_path, name: file_name, ext: ext.sub('.', ''), base: base }

    exif_data = begin
      MiniExiftool.new(file_path)
    rescue StandardError
      {}
    end

    case ext.downcase
    when '.jpg', '.heic', '.png', '.pdf'
      process_image_entry(file_info, exif_data, dirpath, now)
    when '.mov', '.mp4', '.mts', '.mpg', '.avi'
      process_video_entry(file_info, exif_data, dirpath, now)
    when '.m4a'
      process_audio_entry(file_info, dirpath, now)
    when '.aae'
      File.delete(file_info[:path])
      nil
    else
      [now, "debugging: \"#{file_info[:name]}\""]
    end
  end
end
