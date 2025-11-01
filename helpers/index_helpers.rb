# frozen_string_literal: true

require 'mini_exiftool'
require 'rmagick'
require 'fileutils'
require_relative '../lib/video'

module IndexHelpers
  # Generates an index page for a directory of images
  def gen_index(dirpath)
    now = Time.now
    files_data = Dir.glob(File.expand_path("#{data.site.imagerootdir}/diary/#{dirpath}/*")).sort.map do |f|
      _process_file(f, dirpath, now)
    end.compact

    sorted_files_data = files_data.sort_by { |data| data[0] }

    body = _build_body(sorted_files_data)

    File.open("source/diary/#{dirpath}.html.md.erb", 'w') do |f|
      f.puts(body)
    end
  end

  private

  def _build_body(sorted_files_data)
    body = ['---', 'draft: true', 'title: ', '---']
    body.concat(sorted_files_data.map { |data| data[1] })
    body.join("\n")
  end

  def _process_file(file_path, dirpath, now)
    file_name = File.basename(file_path).downcase
    ext = File.extname(file_name)
    base = File.basename(file_name, ext)
    file_info = { path: file_path, name: file_name, ext: ext, base: base }

    exif_data = begin
      MiniExiftool.new(file_path)
    rescue StandardError
      {}
    end

    case ext.downcase
    when '.jpg', '.heic', '.png', '.pdf'
      _process_image(file_info, exif_data, dirpath, now)
    when '.mov', '.mp4', '.mts', '.mpg', '.avi'
      _process_video(file_info, exif_data, dirpath, now)
    when '.m4a'
      _process_audio(file_info, dirpath, now)
    when '.aae'
      File.delete(file_info[:path])
      nil
    else
      [now, "debugging: \"#{file_info[:name]}\""]
    end
  end

  def _process_image(file_info, exif_data, dirpath, now)
    timestamp = exif_data['SubSecDateTimeOriginal'].to_s.sub(/\.\d{3}/, '')
    timestamp = exif_data['DateTimeOriginal'] || now if timestamp.empty?

    text = _image_text(file_info)

    _cache_image(file_info, dirpath) if localhost?

    [timestamp, text]
  end

  def _image_text(file_info)
    if file_info[:ext].downcase == '.png'
      "<%= image \"#{file_info[:base]}\", ext: 'png' %>"
    else
      "<%= image \"#{file_info[:base]}\" %>"
    end
  end

  def _cache_image(file_info, dirpath)
    cache_dir = _ensure_cache_dir(dirpath)
    if ['.jpg', '.heic'].include?(file_info[:ext].downcase)
      _create_image_resolutions(file_info, cache_dir)
    else # .png, .pdf
      FileUtils.copy(file_info[:path], File.join(cache_dir, file_info[:name]))
    end
  end

  def _create_image_resolutions(file_info, cache_dir)
    data.site.heights.each do |height|
      filepath = File.join(cache_dir, "#{file_info[:base]}.#{data.site.thumbext}")
      next if File.exist?(filepath)

      image = Magick::Image.read(file_info[:path]).first
      image.resize_to_fit(0, height).write(filepath)
    end
  end

  def _process_video(file_info, exif_data, dirpath, now)
    opts = localhost? ? Video.probe(file_info[:path]) : nil

    _convert_and_create_poster(file_info, opts, dirpath) if localhost?

    text = _video_text(file_info, opts)
    timestamp = exif_data['CreationDate'] || exif_data['FileModifyDate'] || now

    [timestamp, text]
  end

  def _convert_and_create_poster(file_info, opts, dirpath)
    video_dir = _ensure_cache_dir(dirpath)
    video_path = _convert_video(file_info, opts, video_dir)
    _create_video_poster(video_path, file_info, opts, video_dir)
  end

  def _convert_video(file_info, opts, video_dir)
    video_file = "#{opts[:prefix]}#{file_info[:base]}.#{data.site.videoext}"
    video_path = File.join(video_dir, video_file)

    unless File.exist?(video_path)
      Video.convert(src: file_info[:path], dst_dir: video_dir, dst_file: video_file,
                    opts: opts)
    end
    video_path
  end

  def _create_video_poster(video_path, file_info, opts, video_dir)
    thumb_file = "#{opts[:prefix]}#{file_info[:base]}.#{data.site.thumbext}"
    thumb_path = File.join(video_dir, thumb_file)
    return if File.exist?(thumb_path)

    Video.poster(src: video_path, dst_dir: video_dir, dst_file: thumb_file,
                 height: data.site.thumbheight)
  end

  def _video_text(file_info, opts)
    if file_info[:ext].downcase == '.avi'
      "<%= movie \"#{file_info[:base]}\" %>"
    else
      prefix = opts ? opts[:prefix] : 'hd' # Assume hd if not local
      "<%= movie \"#{prefix}#{file_info[:base]}\" %>"
    end
  end

  def _process_audio(file_info, dirpath, now)
    text = "<%= audio \"#{file_info[:base]}\" %>"

    if localhost?
      cache_dir = _ensure_cache_dir(dirpath)
      FileUtils.copy(file_info[:path], File.join(cache_dir, file_info[:name]))
    end

    [now, text] # Audio files don't have a reliable timestamp in exif
  end

  def _ensure_cache_dir(dirpath)
    cache_dir = File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}")
    FileUtils.mkdir_p(cache_dir)
    cache_dir
  end
end
