require 'spec_helper'
require_relative '../../helpers/index_helpers'

RSpec.describe IndexHelpers do
  let(:helper) { Class.new { include IndexHelpers }.new }

  before do
    allow(helper).to receive(:data).and_return(app.data)
    allow(helper).to receive(:localhost?).and_return(false)
  end

  describe '#gen_index' do
    let(:image_files) { ['/path/to/images/diary/2025/0203-test/img_1234.jpg'] }
    let(:exif_data) { { 'DateTimeOriginal' => Time.new(2025, 2, 3, 12, 0, 0) } }

    before do
      allow(Dir).to receive(:glob).and_return(image_files)
      allow(MiniExiftool).to receive(:new).and_return(exif_data)
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:copy)

      magick_image = double('magick_image')
      allow(magick_image).to receive(:resize_to_fit).and_return(magick_image)
      allow(magick_image).to receive(:write)
      stub_const('Magick::Image', Class.new)
      allow(Magick::Image).to receive(:read).and_return([magick_image])

      stub_const('Video', Class.new)
      allow(Video).to receive(:probe).and_return({ prefix: 'hd' })
      allow(Video).to receive(:convert)
      allow(Video).to receive(:poster)
    end

    after do
      file_path = 'source/diary/2025/0203-test.html.md.erb'
      FileUtils.rm_f(file_path)
    end

    it 'generates an index file with image entries' do
      expect(File).to receive(:open).with('source/diary/2025/0203-test.html.md.erb', 'w')
      helper.gen_index('2025/0203-test')
    end

    context 'with different file types' do
      context 'with jpg files' do
        let(:image_files) { ['/path/to/images/diary/2025/0203-test/img_1234.jpg'] }

        it 'processes jpg files correctly' do
          io = StringIO.new
          expect(File).to receive(:open).with('source/diary/2025/0203-test.html.md.erb', 'w').and_yield(io)
          helper.gen_index('2025/0203-test')
          io.rewind
          output = io.read
          expect(output).to include('<%= image "img_1234" %>')
        end
      end

      context 'with png files' do
        let(:image_files) { ['/path/to/images/diary/2025/0203-test/img_1234.png'] }

        it 'processes png files correctly' do
          io = StringIO.new
          expect(File).to receive(:open).with('source/diary/2025/0203-test.html.md.erb', 'w').and_yield(io)
          helper.gen_index('2025/0203-test')
          io.rewind
          output = io.read
          expect(output).to include('<%= image "img_1234", ext: \'png\' %>')
        end
      end

      context 'with video files' do
        let(:image_files) { ['/path/to/images/diary/2025/0203-test/video_1234.mp4'] }

        it 'processes video files correctly' do
          io = StringIO.new
          expect(File).to receive(:open).with('source/diary/2025/0203-test.html.md.erb', 'w').and_yield(io)
          helper.gen_index('2025/0203-test')
          io.rewind
          output = io.read
          expect(output).to include('<%= movie "hdvideo_1234" %>')
        end
      end

      context 'with audio files' do
        let(:image_files) { ['/path/to/images/diary/2025/0203-test/audio_1234.m4a'] }

        it 'processes audio files correctly' do
          io = StringIO.new
          expect(File).to receive(:open).with('source/diary/2025/0203-test.html.md.erb', 'w').and_yield(io)
          helper.gen_index('2025/0203-test')
          io.rewind
          output = io.read
          expect(output).to include('<%= audio "audio_1234" %>')
        end
      end
    end
  end

  describe 'private methods' do
    let(:now) { Time.new(2025, 1, 1, 0, 0, 0) }
    let(:dirpath) { '2025/0101-test' }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:copy)
      allow(File).to receive(:exist?).and_return(false)
    end

    describe '#_ensure_cache_dir' do
      it 'creates cache directory and returns the path' do
        cache_dir = File.expand_path("#{app.data.site.cacherootdir}/diary/#{dirpath}")
        expect(FileUtils).to receive(:mkdir_p).with(cache_dir)
        result = helper.send(:_ensure_cache_dir, dirpath)
        expect(result).to eq(cache_dir)
      end
    end

    describe '#_process_file' do
      let(:exif_data) { double('exif_data').as_null_object }

      before do
        allow(MiniExiftool).to receive(:new).and_return(exif_data)
      end

      context 'with an image file' do
        it 'calls _process_image' do
          expect(helper).to receive(:_process_image).with({ path: '/path/to/image.jpg', name: 'image.jpg', ext: 'jpg', base: 'image' }, exif_data, dirpath, now)
          helper.send(:_process_file, '/path/to/image.jpg', dirpath, now)
        end
      end

      context 'with a video file' do
        it 'calls _process_video' do
          expect(helper).to receive(:_process_video).with({ path: '/path/to/video.mov', name: 'video.mov', ext: 'mov', base: 'video' }, exif_data, dirpath, now)
          helper.send(:_process_file, '/path/to/video.mov', dirpath, now)
        end
      end

      context 'with an audio file' do
        it 'calls _process_audio' do
          expect(helper).to receive(:_process_audio).with({ path: '/path/to/audio.m4a', name: 'audio.m4a', ext: 'm4a', base: 'audio' }, dirpath, now)
          helper.send(:_process_file, '/path/to/audio.m4a', dirpath, now)
        end
      end

      context 'with an AAE file' do
        it 'deletes the file and returns nil' do
          expect(File).to receive(:delete).with('/path/to/image.aae')
          result = helper.send(:_process_file, '/path/to/image.aae', dirpath, now)
          expect(result).to be_nil
        end
      end

      context 'with an unsupported file' do
        it 'returns a debug message' do
          _timestamp, text = helper.send(:_process_file, '/path/to/unsupported.txt', dirpath, now)
          expect(text).to eq('debugging: "unsupported.txt"')
        end
      end
    end

    describe '#_process_image' do
      let(:file_info) { { path: '/path/to/image.jpg', name: 'image.jpg', ext: 'jpg', base: 'image' } }
      let(:exif_data) { double('exif_data').as_null_object }
      let(:magick_image) { double('magick_image') }

      before do
        stub_const('Magick::Image', Class.new)
        allow(Magick::Image).to receive(:read).and_return([magick_image])
        allow(magick_image).to receive(:resize_to_fit).and_return(magick_image)
        allow(magick_image).to receive(:write)
      end

      it 'returns timestamp and image tag' do
        allow(exif_data).to receive(:[]).with('SubSecDateTimeOriginal').and_return(Time.new(2025, 1, 1, 12, 0, 0).to_s)
        _timestamp, text = helper.send(:_process_image, file_info, exif_data, dirpath, now)
        expect(text).to eq('<%= image "image" %>')
      end
    end

    describe '#_process_video' do
      let(:file_info) { { path: '/path/to/video.mov', name: 'video.mov', ext: '.mov', base: 'video' } }
      let(:exif_data) { double('exif_data').as_null_object }

      before do
        stub_const('Video', Class.new)
        allow(Video).to receive(:probe).and_return({ prefix: 'hd' })
        allow(Video).to receive(:convert)
        allow(Video).to receive(:poster)
      end

      it 'returns timestamp and movie tag' do
        allow(exif_data).to receive(:[]).with('CreationDate').and_return(Time.new(2025, 1, 1, 12, 0, 0))
        _timestamp, text = helper.send(:_process_video, file_info, exif_data, dirpath, now)
        expect(text).to eq('<%= movie "hdvideo" %>')
      end
    end

    describe '#_process_audio' do
      let(:file_info) { { path: '/path/to/audio.m4a', name: 'audio.m4a', ext: '.m4a', base: 'audio' } }

      it 'returns timestamp and audio tag' do
        _timestamp, text = helper.send(:_process_audio, file_info, dirpath, now)
        expect(text).to eq('<%= audio "audio" %>')
      end
    end
  end
end
