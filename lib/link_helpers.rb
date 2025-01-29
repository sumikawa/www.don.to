module LinkHelpers
  # if localhost?
  # @@imagesite = "http://localhost:4567/images"
  # else
  # @@imagesite = "https://www.don.to"
  # end
  @@imagesite = "https://www.don.to"
  @@imageheight = 600
  @@redirectsite = "https://www.don.to"

  def localhost?
    if `hostname`.strip =~ /mbair/
      true
    else
      false
    end
  end

  def dropbox_url(year:, dirname:, basename:, ext:)
    begin
      img_name = "#{basename}.#{ext}"
      img_url = data.image[year][dirname][img_name]

      raise if img_url.nil?

      link_to(image_tag(img_url, height: data.site.thumbheight),
              img_url,
              class: 'image swipe')
    rescue
      # "Error: #{year}, #{dirname}, #{basename}, #{height}, #{data.image.class}, #{data.image.pretty_inspect}"
      image_tag('under.webp', height: data.site.thumbheight)
    end
  end

  def image(file, height: data.site.thumbheight, ext: data.site.thumbext)
    if current_page.url =~ /\.html$/
      dir = current_page.url.sub(%r|\.html$|, '/')
    else
      dir = current_page.url.sub(%r|/[^/]*$|, '/')
    end
    layers = dir.split('/')
    year = layers[2].to_s
    dirname = layers[3].to_s
    basename = file.to_s
    dropbox_url(year: year, dirname: dirname, basename: basename, ext: ext)
  end

  def simage(file, height: 0, ext: 'jpg')
    if current_page.url =~ /\.html$/
      dir = File.expand_path(current_page.url.sub(%r|\.html$|, '/') + File.dirname(file))
    else
      dir = File.expand_path(current_page.url.sub(%r|/[^/]*$|, '/') + File.dirname(file))
    end
    file = File.basename(file)
    if ext == 'jpg'
      height = 300 if height == 0
      if localhost?
        image_tag("#{dir}/#{height}/#{file}.#{ext}")
      else
        "<img src=\"#{@@imagesite}#{dir}/#{height}/#{file}.#{ext}\" srcset=\"#{@@imagesite}#{dir}/#{height}/#{file}.#{ext} 1x, #{@@imagesite}#{dir}/#{height.to_i * 2}/#{file}.#{ext} 2x\" height=\"#{height}\" alt=\"#{file}\"/>"
      end
    else
      height = 300 if height == 0 # height = 0 is not working
      if height == 0
        "<img src=\"#{@@imagesite}#{dir}/#{file}.#{ext}\" alt=\"#{file}\"/>"
      else
        "<img src=\"#{@@imagesite}#{dir}/#{height}/#{file}.#{ext}\" srcset=\"#{@@imagesite}#{dir}/#{height}/#{file}.#{ext} 1x, #{@@imagesite}#{dir}/#{height.to_i * 2}/#{file}.#{ext} 2x\" height=\"#{height}\" alt=\"#{file}\"/>"
      end
    end
  end

  def movie(file)
    if current_page.url =~ /\.html$/
      dir = current_page.url.sub(%r|\.html$|, '/')
    else
      dir = current_page.url.sub(%r|/[^/]*$|, '/')
    end
    layers = dir.split('/')
    year = layers[2].to_s
    dirname = layers[3].to_s
    basename = file.to_s
    begin
      img_name = "#{basename}.#{data.site.videoext}"
      img_url = data.image[year][dirname][img_name]

      thumb_name = "#{basename}.#{data.site.thumbext}"
      thumb_url = data.image[year][dirname][thumb_name]

      "<a href=\"#{img_url}\" class=\"video swipe\">#{image_tag(thumb_url, height: data.site.thumbheight)}</a>"
    rescue
      # puts "Error: #{year}, #{dirname}, #{img_name}, #{img_url}"
      image_tag('under.webp', height: data.site.thumbheight)
    end
  end

  def audio(file)
    if current_page.url =~ /\.html$/
      dir = current_page.url.sub(%r|\.html$|, '/')
    else
      dir = current_page.url.sub(%r|/[^/]*$|, '/')
    end
    "<audio controls><source src=\"#{@@redirectsite}#{dir}#{file}\.m4a\" type=\"audio/aac\"></audio>"
  end

  def static_to(file, comment)
    if current_page.url =~ /\.html$/
      dir = current_page.url.sub(%r|\.html$|, '/')
    else
      dir = current_page.url.sub(%r|/[^/]*$|, '/')
    end
    "<a href=\"#{@@redirectsite}#{dir}#{file}\">#{comment}</a>"
  end
end
