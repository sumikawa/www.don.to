# frozen_string_literal: true

require 'mini_exiftool'
require_relative '../lib/video'

# Custom helpers for the site
module CustomHelpers
  def thisyear
    Dir.glob(File.expand_path("#{data.site.imagerootdir}/diary/[0-9]*")).sort.last.gsub(/[^0-9]/, '')
  end

  def gen_date
    url = current_page.url
    date_str = _extract_date_string(url) || '0000-00-00'
    date_str.gsub('/', '-')
  end

  def gen_title
    url = current_page.url
    date_str = _extract_date_string(url)
    title = current_page.data.title || data.site.notitle

    if date_str.nil?
      title
    elsif date_str.end_with?('年') || date_str.end_with?('以前')
      date_str
    else
      "#{date_str}: #{title}"
    end
  end

  # Generates an Amazon link
  def amazon(title, id)
    link_to(title, "https://www.amazon.co.jp/dp/#{id}/#{data.site.asid}")
  end

  # Generates an index page for a directory of images
  def gen_index(dirpath)
    now = Time.now
    files_data = Dir.glob(File.expand_path("#{data.site.imagerootdir}/diary/#{dirpath}/*")).sort.map do |f|
      _process_file(f, dirpath, now)
    end.compact

    sorted_files_data = files_data.sort_by { |data| data[0] }

    body = ['---', 'draft: true', 'title: ', '---']
    body.concat(sorted_files_data.map { |data| data[1] })

    File.open("source/diary/#{dirpath}.html.md.erb", 'w') do |f|
      f.puts(body.join("\n"))
    end
  end

  # Renders the daylog for a given year
  def rend_daylog(year)
    result = []
    data.daylog.each do |i|
      if i.is_a? String
        md = i.match(%r{(\d\d\d\d)/(\d\d)/(\d\d)})
        result << "<dt>#{i}</dt>" if year == md[1].to_i
      elsif i.is_a? Hash
        log = ''
        comment = ''
        i.each do |k, v|
          if k == 'comment'
            comment = "\n<dd>\t#{v}</dd>".gsub('\\n', "</dd>\n<dd>\t")
          else
            log = "<dt>#{k}: #{v}</dt>"
          end
        end
        md = log.match(%r{(\d\d\d\d)/(\d\d)/(\d\d)})
        result << "#{log}#{comment}" if year == md[1].to_i
      end
    end
    result
  end

  # Generates a link to a diary entry
  def gen_link(filename, title, blanks)
    secret = if filename =~ /secret/
               " #{data.site.secretmes}"
             else
               ''
             end
    target = if blanks == true
               { target: '_blank' }
             else
               {}
             end
    title = data.site.notitle if title == ''
    date = _extract_date_string(filename) || 'UNKNOWN'
    dir = filename.sub(/^source/, '').sub('.md.erb', '')
    "<dt>#{date}: " + link_to(title, dir, target) + "#{secret}</dt>"
  end

  private

  def _extract_date_string(str)
    case str
    when %r{/diary/1995/(\d\d\d\d)(\d\d)(\d\d)-\w+} # Special cases for oldest pages
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/#{::Regexp.last_match(3)}"
    when %r{/diary/1995/(\d\d\d\d)(\d\d)-\w+} # Special cases for oldest pages
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}"
    when /1995/
      '1995年以前'
    when %r{/(\d\d\d\d)/(\d\d)(\d\d)-\w+}
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/#{::Regexp.last_match(3)}"
    when %r{/(\d\d\d\d)/(\d\d)-\w+}
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/??"
    when %r{(\d\d\d\d)(/|\.html)$}
      "#{::Regexp.last_match(1)}年"
    end
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

    text = if file_info[:ext].downcase == '.png'
             "<%= image \"#{file_info[:base]}\", ext: 'png' %>"
           else
             "<%= image \"#{file_info[:base]}\" %>"
           end

    if localhost?
      cache_dir = _ensure_cache_dir(dirpath)
      if ['.jpg', '.heic'].include?(file_info[:ext].downcase)
        data.site.heights.each do |height|
          filepath = File.join(cache_dir, "#{file_info[:base]}.#{data.site.thumbext}")
          next if File.exist?(filepath)

          image = Magick::Image.read(file_info[:path]).first
          image.resize_to_fit(0, height).write(filepath)
        end
      else # .png, .pdf
        FileUtils.copy(file_info[:path], File.join(cache_dir, file_info[:name]))
      end
    end

    [timestamp, text]
  end

  def _process_video(file_info, exif_data, dirpath, now)
    opts = localhost? ? Video.probe(file_info[:path]) : nil

    if localhost?
      video_dir = _ensure_cache_dir(dirpath)
      video_file = "#{opts[:prefix]}#{file_info[:base]}.#{data.site.videoext}"
      video_path = File.join(video_dir, video_file)

      unless File.exist?(video_path)
        Video.convert(src: file_info[:path], dst_dir: video_dir, dst_file: video_file,
                      acodec: data.site.acodec, vcodec: data.site.videoext,
                      opts: opts)
      end

      thumb_file = "#{opts[:prefix]}#{file_info[:base]}.#{data.site.thumbext}"
      thumb_path = File.join(video_dir, thumb_file)
      unless File.exist?(thumb_path)
        Video.poster(src: video_path, dst_dir: video_dir, dst_file: thumb_file,
                     height: data.site.thumbheight)
      end
    end

    text = if file_info[:ext].downcase == '.avi'
             "<%= movie \"#{file_info[:base]}\" %>"
           else
             prefix = opts ? opts[:prefix] : 'hd' # Assume hd if not local
             "<%= movie \"#{prefix}#{file_info[:base]}\" %>"
           end

    timestamp = exif_data['CreationDate'] || exif_data['FileModifyDate'] || now

    [timestamp, text]
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
