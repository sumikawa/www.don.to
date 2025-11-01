module LinkHelpers
  def parse_url(url, file)
    puts "\n"
    puts "old_url: #{url}"

    dir = if url =~ /\.html$/
            url.sub(/\.html$/, '/')
          else
            url.sub(%r{/[^/]*$}, '/')
          end
    url = File.expand_path("#{dir}#{file}")
    layers = url.split('/')
    year = layers[2]
    dirname = layers[3]

    puts "new_url: #{url}"
    puts "dirname: #{dirname}"
    puts "file: #{file}"
    puts "\n"

    [year, dirname, File.basename(file)]
  end

  def dropbox_url(year:, dirname:, basename:, ext:)
    data.image[year][dirname]["#{basename}.#{ext}"] || data.site.error_image
  rescue StandardError
    data.site.error_image
  end

  def image(file, height: data.site.thumbheight, ext: data.site.thumbext)
    year, dirname, file = parse_url(current_page.url, file)
    img_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: ext)

    link_to(image_tag(img_url, height: height),
            img_url,
            class: 'image swipe')
  end

  def simage(file, height: data.site.simageheight, ext: 'jpg')
    year, dirname, file = parse_url(current_page.url, file)
    img_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: ext)

    image_tag(img_url, height: height)
  end

  def movie(file)
    year, dirname, file = parse_url(current_page.url, file)
    video_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: data.site.videoext)
    thumb_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: data.site.thumbext)

    link_to(image_tag(thumb_url, height: data.site.thumbheight),
            video_url,
            class: 'video swipe')
  end

  def audio(file)
    year, dirname, file = parse_url(current_page.url, file)
    audio_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: data.site.audioext)
    # audio_tag(audio_url, controls: true)
    "<audio controls><source src=\"#{audio_url}.#{data.site.audioext}\" type=\"audio/aac\"></audio>"
  end

  def static_to(file, comment)
    year, dirname, file = parse_url(current_page.url, file)
    basename = File.basename(file, '.*')
    ext = File.extname(file).sub('.', '')

    link_url = dropbox_url(year: year, dirname: dirname, basename: basename, ext: ext)
    link_to(comment, link_url)
  end
end
