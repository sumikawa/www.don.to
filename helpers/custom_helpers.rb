require 'mini_exiftool'

module CustomHelpers
  def gen_title
    url = current_page.url
    if current_page.data.title.nil?
      case url
      when /1995/
        title = "1995年以前"
      when /(\d\d\d\d)(\/|\.html)$/
        title = "#{$1}年"
      else
        title = data.site.notitle
      end
    else
      title = current_page.data.title
      title = data.site.notitle if title == ""
      if url =~ /\/diary\/(\d+)\/(\d\d)(\d\d)-\w+\//
        title = "#{$1}\/#{$2}\/#{$3}: #{title}"
      end
    end
    title
  end

  def amazon(title, id)
    link_to(title, "https://www.amazon.co.jp/dp/#{id}/#{data.site.asid}")
  end

  def gen_index(dirpath)
    body = [ "---", "draft: true", "title: ", "---" ]
    newbody = []
    now = Time.now
    Dir.glob(File.expand_path("#{data.site.imagerootdir}/diary/#{dirpath}/*")).sort.each do |f|
      file = File.basename(f).downcase
      ext = File.extname(file)
      base = File.basename(file, ext)
      ex = MiniExiftool.new(f) rescue nil
      t = now
      text = ""

      case ext
      when ".jpg", ".heic"
        text = "<%= image \"#{base}\" %>"
        t = ex['DateTimeOriginal'] || now

        if localhost?
          FileUtils.mkdir_p(File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}"))
          data.site.heights.each do |height|
            filepath = File.expand_path("#{data.site.cacherootdir}/diary/#{dirpath}/#{base}.#{height}.#{data.site.thumbext}")
            unless File.exist?(filepath)
              image = Magick::Image.read(f).first
              image = image.resize_to_fit(0, height)
              image.write(filepath)
            end
          end
        end
      when ".png"
        text = "<%= image \"#{base}\", ext: 'png' %>"
      when ".mov", ".mp4", ".mts"
        text = "<%= movie \"hd#{base}\" %>"
        t = ex['CreationDate'] || ex['FileModifyDate'] || now
      when ".avi"
        text = "<%= movie \"#{base}\" %>"
      when ".m4a"
        text = "<%= audio \"#{base}\" %>"
      when ".aae"
        File.delete(f)
      else
        text = "debugging: \"#{file}\""
      end
#      text = "#{t} #{text}<br />"
      newbody << [ t, text ]
    end

    newbody.sort! {|a, b| a[0] <=> b[0]}
    newbody.each do |n|
      body << n[1]
    end

    File.open("source/diary/#{dirpath}.html.md.erb", "w") do |f|
      f.puts(body.join("\n"))
    end
  end

  def rend_daylog(year)
    result = []
    data.daylog.each do |i|
      if i.is_a? String
        md = i.match(/(\d\d\d\d)\/(\d\d)\/(\d\d)/)
        if year == md[1].to_i
          result << "<dt>#{i}</dt>"
        end
      elsif i.is_a? Hash
        log = ""
        comment = ""
        i.each do |k, v|
          if k == "comment"
            comment = "\n<dd>\t#{v}</dd>".gsub(/\\n/, "</dd>\n<dd>\t")
          else
            log = "<dt>#{k}: #{v}</dt>"
          end
        end
        md = log.match(/(\d\d\d\d)\/(\d\d)\/(\d\d)/)
        if year == md[1].to_i
          result << "#{log}#{comment}"
        end
      end
    end
    result
  end

  def gen_link(filename, title, blanks)
    if filename =~ /secret/
      secret = " #{data.site.secretmes}"
    else
      secret = ''
    end
    if blanks == true
      target = { :target => '_blank' }
    else
      target = {}
    end
    title = data.site.notitle if title == ""
    if filename =~ /(\d\d\d\d)(\d\d)(\d\d)-/
      date = "#{$1}/#{$2}/#{$3}"
    elsif filename =~ /(\d\d\d\d)(\d\d)-/
      date = "#{$1}/#{$2}/??"
    elsif filename =~ /(\d\d\d\d)\/(\d\d)(\d\d)-/
      date = "#{$1}/#{$2}/#{$3}"
    else
      date = "UNKNOWN"
    end
    dir = filename.sub(/^source/, "").sub(/\.md\.erb/, "")
    "<dt>#{date}: " + link_to(title, dir, target) + "#{secret}</dt>"
  end
end
