require 'uri'

module LinkHelpers
  def image_alt_from_url(url)
    path = URI.parse(url).path
    File.basename(path, '.*')
  rescue URI::InvalidURIError
    File.basename(url, '.*')
  end

  def parse_url(url, file)
    dir = if url =~ /\.html$/
            url.sub(/\.html$/, '/')
          else
            url.sub(%r{/[^/]*$}, '/')
          end
    url = File.expand_path("#{dir}#{file}")
    layers = url.split('/')
    year = layers[2]
    dirname = layers[3]

    [year, dirname, File.basename(file)]
  end

  def dropbox_url(year:, dirname:, basename:, ext:)
    data.image[year][dirname]["#{basename}.#{ext}"] || data.site.error_image
  rescue StandardError
    data.site.error_image
  end

  def image(file, height: data.site.thumbheight, ext: data.site.thumbext, timestamp: nil)
    year, dirname, file = parse_url(current_page.url, file)
    img_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: ext)

    link_to(image_tag(img_url, alt: image_alt_from_url(img_url), height: height),
            img_url,
            class: 'image swipe',
            data: { filename: file, timestamp: timestamp } )
  end

  def simage(file, height: data.site.simageheight, ext: 'jpg', grid: true)
    year, dirname, file = parse_url(current_page.url, file)
    img_url = dropbox_url(year: year, dirname: dirname, basename: file, ext: ext)

    attributes = { src: img_url, alt: image_alt_from_url(img_url), height: height }
    classes = ['simage']
    classes << 'no-image-grid' unless grid
    attributes[:class] = classes.join(' ')

    attrs = attributes.map { |key, value| %(#{key}="#{value}") }.join(' ')
    "<img #{attrs} />"
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
    "<audio controls><source src=\"#{audio_url}\" type=\"audio/aac\"></audio>"
  end

  def static_to(file, comment)
    year, dirname, file = parse_url(current_page.url, file)
    basename = File.basename(file, '.*')
    ext = File.extname(file).sub('.', '')

    link_url = dropbox_url(year: year, dirname: dirname, basename: basename, ext: ext)
    link_to(comment, link_url)
  end

  def tag_to(tag)
    normalized_tag = tag.downcase.gsub(' ', '-')
    tag_size = tags_list[tag].nil? ? '?' : tags_list[tag].size
    link_to("/tag/#{normalized_tag}/") do
      "#{tag}<span class=\"tag-count\">#{tag_size}</span>"
    end
  end
end
