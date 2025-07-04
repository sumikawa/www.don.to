require 'mini_exiftool'
require_relative '../lib/video'

module CustomHelpers
  def gen_title
    url = current_page.url
    if current_page.data.title.nil?
      title = case url
              when /1995/
                '1995年以前'
              when %r{(\d\d\d\d)(/|\.html)$}
                "#{::Regexp.last_match(1)}年"
              else
                data.site.notitle
              end
    else
      title = current_page.data.title
      title = data.site.notitle if title == ''
      title = "#{::Regexp.last_match(1)}\/#{::Regexp.last_match(2)}\/#{::Regexp.last_match(3)}: #{title}" if url =~ %r{/diary/(\d+)/(\d\d)(\d\d)-\w+/}
    end
    title
  end

  def amazon(title, id)
    link_to(title, "https://www.amazon.co.jp/dp/#{id}/#{data.site.asid}")
  end

  def gen_index(dirpath)
    body = ['---', 'draft: true', 'title: ', '---']
    newbody = []
    now = Time.now
    Dir.glob(File.expand_path("#{data.site.imagerootdir}/diary/#{dirpath}/*")).sort.each do |f|
      file = File.basename(f).downcase
      ext = File.extname(file)
      base = File.basename(file, ext)
      ex = MiniExiftool.new(f) rescue {}
      t = now
      text = ''

      case ext.downcase
      when '.jpg', '.heic'
        text = "<%= image \"#{base}\" %>"
        t = ex['SubSecDateTimeOriginal'].to_s.sub(/\.\d\d\d/, '')
        t = ex['DateTimeOriginal'] || now if t == ''

        if localhost?
          FileUtils.mkdir_p(File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}"))
          data.site.heights.each do |height|
            filepath = File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}/#{base}.#{data.site.thumbext}")
            next if File.exist?(filepath)

            image = Magick::Image.read(f).first
            image = image.resize_to_fit(0, height)
            image.write(filepath)
          end
        end
      when '.png', '.pdf'
        text = "<%= image \"#{base}\", ext: 'png' %>" if ext.downcase == 'png'

        if localhost?
          FileUtils.mkdir_p(File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}"))
          FileUtils.copy(f, File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}/#{file}"))
        end
      when '.mov', '.mp4', '.mts', '.mpg', '.avi'
        opts = nil

        if localhost?
          # Generate video for external
          opts = Video.probe(f)

          video_dir = File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}")
          video_file = "#{opts[:prefix]}#{base}.#{data.site.videoext}"
          FileUtils.mkdir_p(video_dir)

          thumb_dir = File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}/")
          thumb_file = "#{opts[:prefix]}#{base}.#{data.site.thumbext}"

          unless File.exist?("#{video_dir}/#{video_file}")
            Video.convert(src: f, dst_dir: video_dir, dst_file: video_file,
                          acodec: data.site.acodec, vcodec: data.site.videoext,
                          opts: opts)
          end
          unless File.exist?("#{thumb_dir}/#{thumb_file}")
            Video.poster(src: "#{video_dir}/#{video_file}", dst_dir: thumb_dir, dst_file: thumb_file,
                         height: data.site.thumbheight)
          end
        end

        if ext.downcase == '.avi'
          text = "<%= movie \"#{base}\" %>"
        else
          text = if opts
                   "<%= movie \"#{opts[:prefix]}#{base}\" %>"
                 else
                   # recoginized as HD video if it's already exist
                   "<%= movie \"hd#{base}\" %>"
                 end
          t = ex['CreationDate'] || ex['FileModifyDate'] || now
        end
      when '.m4a'
        text = "<%= audio \"#{base}\" %>"

        if localhost?
          FileUtils.mkdir_p(File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}"))
          FileUtils.copy(f, File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}/#{file}"))
        end
      when '.aae'
        File.delete(f)
      else
        text = "debugging: \"#{file}\""
      end
      #      text = "#{t} #{text}<br />"
      newbody << [t, text]
    end

    newbody.sort! { |a, b| a[0] <=> b[0] }
    newbody.each do |n|
      body << n[1]
    end

    File.open("source/diary/#{dirpath}.html.md.erb", 'w') do |f|
      f.puts(body.join("\n"))
    end
  end

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
            comment = "\n<dd>\t#{v}</dd>".gsub(/\\n/, "</dd>\n<dd>\t")
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
    date = if filename =~ /(\d\d\d\d)(\d\d)(\d\d)-/
             "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/#{::Regexp.last_match(3)}"
           elsif filename =~ /(\d\d\d\d)(\d\d)-/
             "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/??"
           elsif filename =~ %r{(\d\d\d\d)/(\d\d)(\d\d)-}
             "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/#{::Regexp.last_match(3)}"
           else
             'UNKNOWN'
           end
    dir = filename.sub(/^source/, '').sub(/\.md\.erb/, '')
    "<dt>#{date}: " + link_to(title, dir, target) + "#{secret}</dt>"
  end
end
