module LinkHelpers
  if `hostname`.strip =~ /b8e85624ccdc/
    @@imagesite = "http://localhost:8888"
  else
    @@imagesite = "https://www.don.to"
  end
  @@imageheight = 600
  @@thumbheight = 96
  @@redirectsite = "https://www.don.to"

  def image(file, height: @@thumbheight, ext: 'jpg')
    if current_page.url =~ /\.html$/
      dir = current_page.url.sub(%r|\.html$|, '/')
    else
      dir = current_page.url.sub(%r|/[^/]*$|, '/')
    end
    "<a href=\"#{@@imagesite}#{dir}#{@@imageheight}/#{file}.#{ext}\" class=\"image swipe\">#{simage(file, height: height, ext: ext)}</a>"
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
      "<img src=\"#{@@imagesite}#{dir}/#{height}/#{file}.#{ext}\" srcset=\"#{@@imagesite}#{dir}/#{height}/#{file}.#{ext} 1x, #{@@imagesite}#{dir}/#{height.to_i * 2}/#{file}.#{ext} 2x\" height=\"#{height}\" alt=\"#{file}\"/>"
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
    "<a href=\"#{@@redirectsite}#{dir}#{file}\.mp4\" class=\"video swipe\"><img src=\"#{@@imagesite}#{dir}video/#{@@thumbheight}/#{file}.jpg\" height=\"#{@@thumbheight}\" alt=\"#{file}\" /></a>"
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
