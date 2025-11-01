require 'spec_helper'
require_relative '../../helpers/custom_helpers'

RSpec.describe CustomHelpers do
  let(:helper) { Class.new { include CustomHelpers }.new }

  # Mock current_page
  let(:current_page) do
    double('current_page').tap do |page|
      allow(page).to receive(:url).and_return('/diary/2025/0203-test/')
      allow(page).to receive(:data).and_return(
        double('page_data').tap do |page_data|
          allow(page_data).to receive(:title).and_return('Miyakojima Trip')
        end
      )
    end
  end

  before do
    # Stub helper methods to use our mocks
    allow(helper).to receive(:data).and_return(app.data)
    allow(helper).to receive(:current_page).and_return(current_page)
    allow(helper).to receive(:link_to) do |text, url, options = {}|
      target = options[:target] ? " target=\"#{options[:target]}\"" : ''
      "<a href=\"#{url}\"#{target}>#{text}</a>"
    end
    allow(helper).to receive(:localhost?).and_return(false)
  end

  describe '#gen_title' do
    context 'when page has a title' do
      it 'returns the title with date prefix for diary pages' do
        expect(helper.gen_title).to eq('2025/02/03: Miyakojima Trip')
      end

      it 'returns just the title for non-diary pages' do
        allow(current_page).to receive(:url).and_return('/about/')
        expect(helper.gen_title).to eq('Miyakojima Trip')
      end

      it 'returns default title when title is empty' do
        allow(current_page.data).to receive(:title).and_return(nil)
        expect(helper.gen_title).to eq('2025/02/03: no title')
      end
    end

    context 'when page has no title' do
      before do
        allow(current_page.data).to receive(:title).and_return(nil)
      end

      it 'returns "1995年以前" for 1995 URLs' do
        allow(current_page).to receive(:url).and_return('/diary/1995/')
        expect(helper.gen_title).to eq('1995年以前')
      end

      it 'returns year for year URLs' do
        allow(current_page).to receive(:url).and_return('/diary/2025/')
        expect(helper.gen_title).to eq('2025年')

        allow(current_page).to receive(:url).and_return('/diary/2025.html')
        expect(helper.gen_title).to eq('2025年')
      end

      it 'returns default title for other URLs' do
        allow(current_page).to receive(:url).and_return('/about/')
        expect(helper.gen_title).to eq('no title')
      end
    end
  end

  describe '#amazon' do
    it 'generates an Amazon link with the correct URL and affiliate ID' do
      result = helper.amazon('Book Title', '1234567890')
      expect(result).to eq('<a href="https://www.amazon.co.jp/dp/1234567890/daydreaonthen-22">Book Title</a>')
    end
  end

  describe '#gen_index' do
    let(:image_files) { ['/path/to/images/diary/2025/0203-test/img_1234.jpg'] }
    let(:exif_data) { { 'DateTimeOriginal' => Time.new(2025, 2, 3, 12, 0, 0) } }

    before do
      # Stub Dir methods
      allow(Dir).to receive(:glob).and_return(image_files)

      # Stub MiniExiftool
      allow(MiniExiftool).to receive(:new).and_return(exif_data)

      # Stub FileUtils
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:copy)

      # Stub helper methods
      allow(helper).to receive(:localhost?).and_return(true)
      allow(helper).to receive(:image).and_return('<img src="img_1234.jpg" />')

      # Stub Magick::Image
      magick_image = double('magick_image')
      allow(magick_image).to receive(:resize_to_fit).and_return(magick_image)
      allow(magick_image).to receive(:write)
      allow(Magick::Image).to receive(:read).and_return([magick_image])

      # Stub Video methods
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

  describe '#rend_daylog' do
    it 'renders daylog entries for the specified year' do
      result = helper.rend_daylog(2025)
      expect(result).to include('<dt>2025/10/29: 「<a href="https://www.amazon.co.jp/dp/B08XQ65HP7/daydreaonthen-22">かがみの孤城 上</a>」、辻村深月、ポプラ文庫</dt>')
      expect(result).to include("<dt>2025/10/10: サイト内検索ライブラリを変更</dt>\n<dd>\t<a href=\"https://www.algolia.com/\">Algolia</a>から<a href=\"https://pagefind.app/\">pagefind</a>に変えた</dd>")
      expect(result).not_to include('2024')
    end
  end

  describe '#gen_link' do
    context 'with regular filename' do
      it 'generates a link with date information' do
        result = helper.gen_link('source/diary/2025/0203-test.html.md.erb', 'Miyakojima Trip', false)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/2025/0203-test.html">Miyakojima Trip</a></dt>')
      end
    end

    context 'with secret filename' do
      it 'adds secret message to the link' do
        result = helper.gen_link('source/diary/2025/0203-secret.html.md.erb', 'Secret Trip', false)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/2025/0203-secret.html">Secret Trip</a> (要パスワード)</dt>')
      end
    end

    context 'with blank target' do
      it 'adds target="_blank" to the link' do
        result = helper.gen_link('source/diary/2025/0203-test.html.md.erb', 'Miyakojima Trip', true)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/2025/0203-test.html" target="_blank">Miyakojima Trip</a></dt>')
      end
    end

    context 'with empty title' do
      it 'uses default title' do
        result = helper.gen_link('source/diary/2025/0203-test.html.md.erb', '', false)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/2025/0203-test.html">no title</a></dt>')
      end
    end

    context 'with different date formats' do
      it 'handles YYYYMM format' do
        result = helper.gen_link('source/diary/2025/02-test.html.md.erb', 'Miyakojima Trip', false)
        expect(result).to eq('<dt>2025/02/??: <a href="/diary/2025/02-test.html">Miyakojima Trip</a></dt>')
      end

      it 'handles YYYY/MMDD format' do
        result = helper.gen_link('source/diary/2025/0203-test.html.md.erb', 'Miyakojima Trip', false)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/2025/0203-test.html">Miyakojima Trip</a></dt>')
      end

      it 'handles unknown format' do
        result = helper.gen_link('source/diary/miyakojima.html.md.erb', 'Miyakojima Trip', false)
        expect(result).to eq('<dt>UNKNOWN: <a href="/diary/miyakojima.html">Miyakojima Trip</a></dt>')
      end
    end
  end

  describe 'private methods' do
    let(:now) { Time.new(2025, 1, 1, 0, 0, 0) }
    let(:dirpath) { '2025/0101-test' }

    before do
      allow(helper).to receive(:localhost?).and_return(true)
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
          expect(helper).to receive(:_process_image).with({ path: '/path/to/image.jpg', name: 'image.jpg', ext: '.jpg', base: 'image' }, exif_data, dirpath, now)
          helper.send(:_process_file, '/path/to/image.jpg', dirpath, now)
        end
      end

      context 'with a video file' do
        it 'calls _process_video' do
          expect(helper).to receive(:_process_video).with({ path: '/path/to/video.mov', name: 'video.mov', ext: '.mov', base: 'video' }, exif_data, dirpath, now)
          helper.send(:_process_file, '/path/to/video.mov', dirpath, now)
        end
      end

      context 'with an audio file' do
        it 'calls _process_audio' do
          expect(helper).to receive(:_process_audio).with({ path: '/path/to/audio.m4a', name: 'audio.m4a', ext: '.m4a', base: 'audio' }, dirpath, now)
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
      let(:file_info) { { path: '/path/to/image.jpg', name: 'image.jpg', ext: '.jpg', base: 'image' } }
      let(:exif_data) { double('exif_data').as_null_object }
      let(:magick_image) { double('magick_image') }

      before do
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

    describe '#_extract_date_string' do
      it 'extracts date from various string formats' do
        expect(helper.send(:_extract_date_string, '/diary/1995/198508-camp/')).to eq('1985/08')
        expect(helper.send(:_extract_date_string, '/diary/2025/0101-test/')).to eq('2025/01/01')
        expect(helper.send(:_extract_date_string, 'source/diary/2025/0101-test.html.md.erb')).to eq('2025/01/01')
        expect(helper.send(:_extract_date_string, 'source/diary/2025/01-test.html.md.erb')).to eq('2025/01/??')
        expect(helper.send(:_extract_date_string, '/diary/2025/')).to eq('2025年')
        expect(helper.send(:_extract_date_string, '/diary/2025.html')).to eq('2025年')
        expect(helper.send(:_extract_date_string, '/diary/1995/')).to eq('1995年以前')
        expect(helper.send(:_extract_date_string, 'foobar')).to be_nil
      end
    end
  end
end
