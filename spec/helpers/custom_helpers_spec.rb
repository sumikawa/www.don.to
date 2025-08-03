require 'spec_helper'
require_relative '../../helpers/custom_helpers'

RSpec.describe CustomHelpers do
  let(:helper) { Class.new { include CustomHelpers }.new }

  # Mock data object
  let(:data_mock) do
    double('data').tap do |data|
      allow(data).to receive(:site).and_return(
        double('site').tap do |site|
          allow(site).to receive(:notitle).and_return('No Title')
          allow(site).to receive(:asid).and_return('tag=example-22')
          allow(site).to receive(:secretmes).and_return('(secret)')
          allow(site).to receive(:imagerootdir).and_return('/path/to/images')
          allow(site).to receive(:cacherootdir).and_return('/path/to/cache')
          allow(site).to receive(:heights).and_return([200, 400])
          allow(site).to receive(:thumbext).and_return('jpg')
          allow(site).to receive(:videoext).and_return('mp4')
          allow(site).to receive(:thumbheight).and_return(200)
          allow(site).to receive(:acodec).and_return('aac')
        end
      )

      allow(data).to receive(:daylog).and_return([
                                                   { '2025/01/01' => 'Event 1' },
                                                   { '2024/12/31' => 'Event 2' },
                                                   { '2025/01/02' => 'Event 3', 'comment' => 'This is a comment' },
                                                   { '2024/12/30' => 'Event 4', 'comment' => 'Another comment' },
                                                 ])
    end
  end

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
    allow(helper).to receive(:data).and_return(data_mock)
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
        allow(current_page.data).to receive(:title).and_return('')
        expect(helper.gen_title).to eq('2025/02/03: No Title')
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
        expect(helper.gen_title).to eq('No Title')
      end
    end
  end

  describe '#amazon' do
    it 'generates an Amazon link with the correct URL and affiliate ID' do
      result = helper.amazon('Book Title', '1234567890')
      expect(result).to eq('<a href="https://www.amazon.co.jp/dp/1234567890/tag=example-22">Book Title</a>')
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

    it 'generates an index file with image entries' do
      expect(File).to receive(:open).with('source/diary/2025/0203-test.html.md.erb', 'w')
      helper.gen_index('2025/0203-test')
    end

    context 'with different file types' do
      context 'with jpg files' do
        let(:image_files) { ['/path/to/images/diary/2025/0203-test/img_1234.jpg'] }

        it 'processes jpg files correctly' do
          expect(helper).to receive(:image).with('img_1234')
          helper.gen_index('2025/0203-test')
        end
      end

      context 'with png files' do
        let(:image_files) { ['/path/to/images/diary/2025/0203-test/img_1234.png'] }

        it 'processes png files correctly' do
          expect(helper).to receive(:image).with('img_1234', ext: 'png')
          helper.gen_index('2025/0203-test')
        end
      end

      context 'with video files' do
        let(:image_files) { ['/path/to/images/diary/2025/0203-test/video_1234.mp4'] }

        it 'processes video files correctly' do
          expect(helper).to receive(:movie).with('hdvideo_1234')
          helper.gen_index('2025/0203-test')
        end
      end

      context 'with audio files' do
        let(:image_files) { ['/path/to/images/diary/2025/0203-test/audio_1234.m4a'] }

        it 'processes audio files correctly' do
          expect(helper).to receive(:audio).with('audio_1234')
          helper.gen_index('2025/0203-test')
        end
      end
    end
  end

  describe '#rend_daylog' do
    it 'renders daylog entries for the specified year' do
      result = helper.rend_daylog(2025)
      expect(result).to include('<dt>2025/01/01: Event 1</dt>')
      expect(result).to include("<dt>2025/01/02: Event 3</dt>\n<dd>\tThis is a comment</dd>")
      expect(result).not_to include('<dt>2024/12/31: Event 2</dt>')
      expect(result).not_to include('<dt>2024/12/30: Event 4</dt>')
    end
  end

  describe '#gen_link' do
    context 'with regular filename' do
      it 'generates a link with date information' do
        result = helper.gen_link('source/diary/20250203-test.html.md.erb', 'Miyakojima Trip', false)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/20250203-test.html">Miyakojima Trip</a></dt>')
      end
    end

    context 'with secret filename' do
      it 'adds secret message to the link' do
        result = helper.gen_link('source/diary/20250203-secret.html.md.erb', 'Secret Trip', false)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/20250203-secret.html">Secret Trip</a> (secret)</dt>')
      end
    end

    context 'with blank target' do
      it 'adds target="_blank" to the link' do
        result = helper.gen_link('source/diary/20250203-test.html.md.erb', 'Miyakojima Trip', true)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/20250203-test.html" target="_blank">Miyakojima Trip</a></dt>')
      end
    end

    context 'with empty title' do
      it 'uses default title' do
        result = helper.gen_link('source/diary/20250203-test.html.md.erb', '', false)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/20250203-test.html">No Title</a></dt>')
      end
    end

    context 'with different date formats' do
      it 'handles YYYYMM format' do
        result = helper.gen_link('source/diary/202502-test.html.md.erb', 'Miyakojima Trip', false)
        expect(result).to eq('<dt>2025/02/??: <a href="/diary/202502-test.html">Miyakojima Trip</a></dt>')
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
end
