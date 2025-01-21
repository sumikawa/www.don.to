module LinkHelpers
  # if localhost?
  # @@imagesite = "http://localhost:4567/images"
  # else
  # @@imagesite = "https://www.don.to"
  # end
  @@imagesite = "https://www.don.to"
  @@imageheight = 600
  @@thumbheight = 96
  @@redirectsite = "https://www.don.to"

  def localhost?
    if `hostname`.strip =~ /mbair/
      true
    else
      false
    end
  end

  def dropbox_url(year:, dirname:, basename:, ext: 'jpg')
    begin
      imgsrc_name = "#{basename}.#{@@imageheight}.#{ext}"
      img_name = "#{basename}.#{@@imageheight}.#{ext}"
      imgsrc = data.image[year][dirname][imgsrc_name]
      img = data.image[year][dirname][img_name]

      "<img src=\"#{imgsrc}\" height=\"160\"/>"
      # "<img src=\"#{imgsrc}\" height=\"160\"/>",
      #        img,
      #        class: 'image swipe')
    rescue
      # "Error: #{year}, #{dirname}, #{basename}, #{height}, #{data.image.class}, #{data.image.pretty_inspect}"
      link_to(image_tag('under_idx.jpg'), image_path('under.jpg'), class: 'image swipe')
    end
  end

  def image(file, height: @@thumbheight, ext: 'jpg')
    if current_page.url =~ /\.html$/
      dir = current_page.url.sub(%r|\.html$|, '/')
    else
      dir = current_page.url.sub(%r|/[^/]*$|, '/')
    end
    layers = dir.split('/')
    year = layers[2].to_s
    dirname = layers[3].to_s
    basename = file.to_s
    dropbox_url(year: year, dirname: dirname, basename: basename)
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
    ext = 'mp4'
    begin
      imgsrc_name = "#{basename}.#{ext}"
      imgsrc = data.image[year][dirname][imgsrc_name]
      # "<a href=\"#{@@redirectsite}#{dir}#{file}\.mp4\" class=\"video swipe\"><img src=\"#{@@imagesite}#{dir}video/#{@@thumbheight}/#{file}.jpg\" height=\"#{@@thumbheight}\" alt=\"#{file}\" /></a>"
      "<video controls height=\"160\"><source src=\"#{imgsrc}\" /></video>"
    rescue
      link_to(image_tag('under_idx.jpg'), image_path('under.jpg'), class: 'image swipe')
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
