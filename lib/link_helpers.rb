module LinkHelpers
  # if localhost?
  # @@imagesite = "http://localhost:4567/images"
  # else
  # @@imagesite = "https://www.don.to"
  # end
  @@imagesite = "https://www.don.to"
  @@redirectsite = "https://www.don.to"

  def localhost?
    if `hostname`.strip =~ /mbair/
      true
    else
      false
    end
  end

  def parse_url(file, url)
    if url =~ /\.html$/
      dir = url.sub(%r|\.html$|, '/')
    else
      dir = url.sub(%r|/[^/]*$|, '/')
    end
    layers = dir.split('/')
    year = layers[2].to_s
    dirname = layers[3].to_s
    basename = file.to_s

    return year, dirname, basename
  end

  def dropbox_url(year:, dirname:, basename:, ext:)
    begin
      data.image[year][dirname]["#{basename}.#{ext}"]
    rescue
      nil
    end
  end

  def image(file, height: data.site.thumbheight, ext: data.site.thumbext)
    year, dirname, basename = parse_url(file, current_page.url)
    img_url = dropbox_url(year: year, dirname: dirname, basename: basename, ext: ext)

    if img_url.nil?
      # "Error: #{year}, #{dirname}, #{basename}, #{height}, #{data.image.class}, #{data.image.pretty_inspect}"
      image_tag('under.webp', height: data.site.thumbheight)
    else
      link_to(image_tag(img_url, height: data.site.thumbheight),
              img_url,
              class: 'image swipe')
    end
  end

  def simage(file, height: 0, ext: 'jpg')
    year, dirname, basename = parse_url(file, current_page.url)
    img_url = dropbox_url(year: year, dirname: dirname, basename: basename, ext: ext) || 'under.webp'

    if height == 0
      image_tag(img_url)
    else
      image_tag(img_url, height: height)
    end
  end

  def movie(file)
    year, dirname, basename = parse_url(file, current_page.url)
    begin
      img_name = "#{basename}.#{data.site.videoext}"
      img_url = data.image[year][dirname][img_name]

      thumb_name = "#{basename}.#{data.site.thumbext}"
      thumb_url = data.image[year][dirname][thumb_name] || 'under.webp'

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
