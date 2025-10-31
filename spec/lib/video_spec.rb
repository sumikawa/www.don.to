require 'spec_helper'
require_relative '../../lib/video'

sample1 = <<~FFMPEG
  Duration: 00:00:28.24, start: 0.000000, bitrate: 9656 kb/s
  Stream #0:0[0x1](und): Video: hevc (Main 10) (hvc1 / 0x31637668), yuv420p10le(tv, bt2020nc/bt2020/arib-std-b67), 1920x1080, 9400 kb/s, 29.99 fps, 30 tbr, 600 tbn (default)
      Metadata:
        creation_time   : 2024-11-03T05:35:07.000000Z
        handler_name    : Core Media Video
        vendor_id       : [0][0][0][0]
        encoder         : HEVC
      Side data:
        DOVI configuration record: version: 1.0, profile: 8, level: 4, rpu flag: 1, el flag: 0, bl flag: 1, compatibility id: 4, compression: 0
        Ambient Viewing Environment, ambient_illuminance=314.000000, ambient_light_x=0.312700, ambient_light_y=0.329000
  Stream #0:1[0x2](und): Audio: aac (LC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 198 kb/s (default)
      Metadata:
        creation_time   : 2024-11-03T05:35:07.000000Z
        handler_name    : Core Media Audio
        vendor_id       : [0][0][0][0]
FFMPEG

sample2 = <<~FFMPEG
  Duration: 00:00:10.27, start: 0.000000, bitrate: 14589 kb/s
  Stream #0:0[0x1](und): Video: hevc (Main 10) (hvc1 / 0x31637668), yuv420p10le(tv, bt2020nc/bt2020/arib-std-b67), 1920x1080, 14342 kb/s, 30 fps, 29.97 tbr, 600 tbn (default)
      Metadata:
        creation_time   : 2024-10-20T04:28:38.000000Z
        handler_name    : Core Media Video
        vendor_id       : [0][0][0][0]
        encoder         : HEVC
      Side data:
        DOVI configuration record: version: 1.0, profile: 8, level: 4, rpu flag: 1, el flag: 0, bl flag: 1, compatibility id: 4, compression: 0
        displaymatrix: rotation of -90.00 degrees
        Ambient Viewing Environment, ambient_illuminance=314.000000, ambient_light_x=0.312700, ambient_light_y=0.329000
  Stream #0:1[0x2](und): Audio: aac (LC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 182 kb/s (default)
FFMPEG

class Video
  def self.data
    # This will be mocked in the test
  end
end

RSpec.describe do
  describe 'detect' do
    # Mock data object
    let(:data_mock) do
      double('data').tap do |data|
        allow(data).to receive(:site).and_return(
          double('site').tap do |site|
            allow(site).to receive(:acodec).and_return('aac')
            allow(site).to receive(:vcodec).and_return('mp4')
          end
        )
      end
    end

    before do
      allow(Video).to receive(:data).and_return(data_mock)
    end

    it 'return hdvideo' do
      result = Video.detect(sample1)
      expect(result).to eq({
                             aspect: '16:9',
                             ext_opt: '',
                             pixel: '480x270',
                             prefix: 'hd',
                             rotate: 0,
                             rotate_opt: '',
                           })
    end

    it 'return hdtrvideo' do
      result = Video.detect(sample2)
      expect(result).to eq({
                             aspect: '9:16',
                             ext_opt: '',
                             pixel: '270x480',
                             prefix: 'hdtr',
                             rotate: -90,
                             rotate_opt: '-metadata:s:v:0 rotate=0',
                           })
    end

    it 'return ffmpeg to generate hdvideo' do
      result = Video.cmd_opts(opts: Video.detect(sample1))
      expect(result).to eq('-g 120 -vcodec libx264 -s 480x270 -bt 1536k -movflags faststart -f mp4 -acodec aac -ar 32000 -ac 1 -ab 48k')
    end

    it 'return ffmpeg to generate hdtrvideo' do
      result = Video.cmd_opts(opts: Video.detect(sample2))
      expect(result).to eq('-metadata:s:v:0 rotate=0 -g 120 -vcodec libx264 -s 270x480 -bt 1536k -movflags faststart -f mp4 -acodec aac -ar 32000 -ac 1 -ab 48k')
    end
  end
end
