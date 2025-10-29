# LinkHelpers
module LinkHelpers
  def localhost?
    if `hostname`.strip =~ /mbair/
      true
    else
      false
    end
  end

  def parse_url(url)
    dir = if url =~ /\.html$/
            url.sub(/\.html$/, '/')
          else
            url.sub(%r{/[^/]*$}, '/')
          end
    layers = dir.split('/')
    year = layers[2].to_s
    dirname = layers[3].to_s

    [year, dirname]
  end

  def dropbox_url(year:, dirname:, basename:, ext:)
    data.image[year][dirname]["#{basename}.#{ext}"] || data.site.error_image
  rescue StandardError
    data.site.error_image
  end

  def image(file, height: data.site.thumbheight, ext: data.site.thumbext)
    year, dirname = parse_url(current_page.url)
    img_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: ext)

    link_to(image_tag(img_url, height: height),
            img_url,
            class: 'image swipe')
  end

  def simage(file, height: 0, ext: 'jpg')
    year, dirname = parse_url(current_page.url)
    img_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: ext)

    if height.zero?
      image_tag(img_url)
    else
      image_tag(img_url, height: height)
    end
  end

  def movie(file)
    year, dirname = parse_url(current_page.url)
    video_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: data.site.videoext)
    thumb_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: data.site.thumbext)

    link_to(image_tag(thumb_url, height: data.site.thumbheight),
            video_url,
            class: 'video swipe')
  end

  def audio(file)
    year, dirname = parse_url(current_page.url)
    audio_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: data.site.audioext)
    # audio_tag(audio_url, controls: true)
    "<audio controls><source src=\"#{audio_url}.#{data.site.audioext}\" type=\"audio/aac\"></audio>"
  end

  def static_to(file, comment)
    year, dirname = parse_url(current_page.url)
    basename = File.basename(file, '.*')
    ext = File.extname(file).sub('.', '')

    puts basename
    puts ext

    link_url = dropbox_url(year: year, dirname: dirname, basename: basename, ext: ext)
    link_to(comment, link_url)
  end
end
