# frozen_string_literal: true

require 'mini_exiftool'
require 'rmagick'
require 'fileutils'
require 'rbconfig'
require_relative '../lib/video'
require_relative 'diary_media_helpers'

module DiaryIndexHelpers
  def gen_index(dirpath)
    now = Time.now
    files_data = Dir.glob(File.expand_path("#{data.site.imagerootdir}/diary/#{dirpath}/*")).sort.map do |file_path|
      process_index_file(file_path, dirpath, now)
    end.compact

    body = build_index_body(files_data)

    write_index(dirpath, body)
    schedule_image_catalog(dirpath) if localhost?
  end

  private

  def write_index(dirpath, body)
    File.open("source/diary/#{dirpath}.html.md.erb", 'w') { |file| file.puts(body) }
  end

  def schedule_image_catalog(dirpath)
    root = File.expand_path('..', __dir__)
    FileUtils.mkdir_p(File.join(root, 'logs'))
    pid = Process.spawn(RbConfig.ruby, File.join(root, 'scripts/gen_image.rb'), dirpath,
                        chdir: root, out: [File.join(root, 'logs/gen_image.log'), 'a'], err: %i[child out])
    Process.detach(pid)
  rescue SystemCallError => e
    warn "Image catalog could not start: #{e.message}"
  end

  def build_index_body(files_data)
    sorted_files_data = files_data.sort_by { |data| data[0] }
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
