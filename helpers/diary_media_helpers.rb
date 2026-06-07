# frozen_string_literal: true

require 'time'

module DiaryIndexHelpers
  private

  def normalized_media_timestamp(timestamp, fallback)
    value = timestamp || fallback
    return value.strftime('%Y-%m-%d %H:%M:%S') if value.respond_to?(:strftime)

    string = value.to_s.sub(/\.\d{3}/, '').sub(/\A(\d{4}):(\d{2}):(\d{2})/, '\1-\2-\3')
    Time.parse(string).strftime('%Y-%m-%d %H:%M:%S')
  rescue ArgumentError
    string
  end

  def process_image_entry(file_info, exif_data, dirpath, now)
    timestamp = exif_data['SubSecDateTimeOriginal']
    timestamp = exif_data['DateTimeOriginal'] || now if timestamp.to_s.empty?
    timestamp = normalized_media_timestamp(timestamp, now)

    text = if file_info[:ext] == 'png'
             "<%= image \"#{file_info[:base]}\", ext: '#{file_info[:ext]}', timestamp: '#{timestamp}' %>"
           else
             "<%= image \"#{file_info[:base]}\", timestamp: '#{timestamp}' %>"
           end

    cache_image(file_info, dirpath) if localhost?

    [timestamp, text]
  end

  def cache_image(file_info, dirpath)
    cache_dir = ensure_cache_dir(dirpath)
    if %w[jpg heic].include?(file_info[:ext].downcase)
      create_image_resolutions(file_info, cache_dir)
    else
      FileUtils.copy(file_info[:path], File.join(cache_dir, file_info[:name]))
    end
  end

  def create_image_resolutions(file_info, cache_dir)
    data.site.heights.each do |height|
      filepath = File.join(cache_dir, "#{file_info[:base]}.#{data.site.thumbext}")
      next if File.exist?(filepath)

      image = Magick::Image.read(file_info[:path]).first
      image.strip!
      image.resize_to_fit(0, height).write(filepath)
    end
  end

  def process_video_entry(file_info, exif_data, dirpath, now)
    opts = localhost? ? Video.probe(file_info[:path]) : nil

    convert_video_and_create_poster(file_info, opts, dirpath) if localhost?

    text = video_embed_text(file_info, opts)
    timestamp = exif_data['CreationDate'] || exif_data['FileModifyDate'] || now

    [timestamp, text]
  end

  def convert_video_and_create_poster(file_info, opts, dirpath)
    opts[:vcodec] = data.site.vcodec
    opts[:acodec] = data.site.acodec
    video_dir = ensure_cache_dir(dirpath)
    video_path = convert_video(file_info, opts, video_dir)
    create_video_poster(video_path, file_info, opts, video_dir)
  end

  def convert_video(file_info, opts, video_dir)
    video_file = "#{opts[:prefix]}#{file_info[:base]}.#{data.site.videoext}"
    video_path = File.join(video_dir, video_file)

    unless File.exist?(video_path)
      Video.convert(src: file_info[:path], dst_dir: video_dir, dst_file: video_file,
                    opts: opts)
    end
    video_path
  end

  def create_video_poster(video_path, file_info, opts, video_dir)
    thumb_file = "#{opts[:prefix]}#{file_info[:base]}.#{data.site.thumbext}"
    thumb_path = File.join(video_dir, thumb_file)
    return if File.exist?(thumb_path)

    Video.poster(src: video_path, dst_dir: video_dir, dst_file: thumb_file,
                 height: data.site.thumbheight)
  end

  def video_embed_text(file_info, opts)
    if file_info[:ext].downcase == 'avi'
      "<%= movie \"#{file_info[:base]}\" %>"
    else
      prefix = opts ? opts[:prefix] : 'hd'
      "<%= movie \"#{prefix}#{file_info[:base]}\" %>"
    end
  end

  def process_audio_entry(file_info, dirpath, now)
    text = "<%= audio \"#{file_info[:base]}\" %>"

    if localhost?
      cache_dir = ensure_cache_dir(dirpath)
      FileUtils.copy(file_info[:path], File.join(cache_dir, file_info[:name]))
    end

    [now, text]
  end

  def ensure_cache_dir(dirpath)
    cache_dir = File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}")
    FileUtils.mkdir_p(cache_dir)
    cache_dir
  end
end
