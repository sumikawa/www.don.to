module LinkHelpers
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
      data.image[year][dirname]["#{basename}.#{ext}"] || data.site.error_image
    rescue
      data.site.error_image
    end
  end

  def image(file, height: data.site.thumbheight, ext: data.site.thumbext)
    year, dirname, basename = parse_url(file, current_page.url)
    img_url = dropbox_url(year: year, dirname: dirname, basename: basename, ext: ext)

    link_to(image_tag(img_url, height: data.site.thumbheight),
            img_url,
            class: 'image swipe')
  end

  def simage(file, height: 0, ext: 'jpg')
    year, dirname, basename = parse_url(file, current_page.url)
    img_url = dropbox_url(year: year, dirname: dirname, basename: basename, ext: ext)

    if height == 0
      image_tag(img_url)
    else
      image_tag(img_url, height: height)
    end
  end

  def movie(file)
    year, dirname, basename = parse_url(file, current_page.url)
    video_url = dropbox_url(year: year, dirname: dirname, basename: basename, ext: data.site.videoext)
    thumb_url = dropbox_url(year: year, dirname: dirname, basename: basename, ext: data.site.thumbext)

    link_to(image_tag(thumb_url, height: data.site.thumbheight),
            video_url,
            class: 'video swipe')
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
