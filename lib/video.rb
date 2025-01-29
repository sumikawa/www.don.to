class Video
  class << self
    def detect(report)
      rotate = 0
      pixel = ''
      prefix = ''
      aspect = ''
      extops = ''
      lines = report.split("\n")
      lines.each do |line|
        if md = line.match(/(rotate\s+:|rotation\s+of)\s+([-\d]+)/)
          rotate = md[2].to_i
        end
      end
      lines.each do |line|
        if line =~ /Stream .*Video/
          case line
          when / DAR 16:9|960x540|1280x720|1920x1080|3840x2160/
            if rotate == 0 || rotate == -180
              pixel = '480x270'
              prefix = 'hd'
              aspect = '16:9'
            else
              pixel = '270x480'
              prefix = 'hdtr'
              aspect = '9:16'
            end
          when / DAR 9:16|540x960|720x1280|1080x1920|2160x3840/
            pixel = '270x480'
            prefix = 'hdtr'
            aspect = '9:16'
          when / DAR 4:3|320x240|352x240|640x480|1440x1080/
            if rotate == 0 || rotate == -180
              pixel = '480x360'
              prefix = ''
              aspect = '4:3'
            else
              pixel = '360x480'
              prefix = 'tr'
              aspect = '3:4'
            end
          when / DAR 3:4|240x320/
            pixel = '360x480'
            prefix = 'tr'
            aspect = '3:4'
          end
          case line
          when /(120) fps/
            extops = "-vf 'setpts=4*PTS' -r 30 -filter:a 'atempo=0.5'"
          when /(239\.98) fps/
            extops = "-vf 'setpts=4*PTS' -r 30 -filter:a 'atempo=0.5,atempo=0.5'"
          end
        end
      end
      { rotate: rotate, pixel: pixel, prefix: prefix, aspect: aspect, extops: extops }
    end

    def cmd_opts(report)
      result = detect(report)
      acodec = 'aac'
      vcodec = 'mp4'
      "#{result[:rotateopt]} -g 120 -vcodec libx264 -s #{result[:pixel]} -bt 1024k -acodec #{acodec} -ar 32000 -ac 1 -ab 48k -movflags faststart #{result[:extops]} -f #{vcodec}"
    end
  end
end
