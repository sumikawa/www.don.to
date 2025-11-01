require 'spec_helper'
require_relative '../../helpers/link_helpers'

RSpec.describe LinkHelpers do
  let(:helper) { Class.new { include LinkHelpers }.new }

  # Mock current_page
  let(:current_page) do
    double('current_page').tap do |page|
      allow(page).to receive(:url).and_return('/diary/1995/198508-camp/')
    end
  end

  before do
    # Stub helper methods to use our mocks
    allow(helper).to receive(:data).and_return(app.data)
    allow(helper).to receive(:current_page).and_return(current_page)
    allow(helper).to receive(:link_to) do |text, url, options = {}|
      "<a href=\"#{url}\" class=\"#{options[:class]}\">#{text}</a>"
    end
    allow(helper).to receive(:image_tag) do |url, options = {}|
      if options[:height]
        "<img src=\"#{url}\" height=\"#{options[:height]}\" />"
      else
        "<img src=\"#{url}\" />"
      end
    end
  end

  describe '#parse_url' do
    context 'with URL ending in /' do
      it 'extracts year and dirname correctly' do
        year, dirname, file = helper.parse_url('/diary/1995/198508-camp.html', 'file.jpg')
        expect(year).to eq('1995')
        expect(dirname).to eq('198508-camp')
        expect(file).to eq('file.jpg')
      end

      it 'extracts year and dirname correctly with relative path #1' do
        year, dirname, file = helper.parse_url('/diary/2004/0508-camp.html', '../1223-test/file.jpg')
        expect(year).to eq('2004')
        expect(dirname).to eq('1223-test')
        expect(file).to eq('file.jpg')
      end

      it 'extracts year and dirname correctly with relative path #2' do
        year, dirname, file = helper.parse_url('/diary/1995/198508-camp.html', '../../2001/1223-test/file.jpg')
        expect(year).to eq('2001')
        expect(dirname).to eq('1223-test')
        expect(file).to eq('file.jpg')
      end
    end

    context 'with URL ending in /' do
      it 'extracts year and dirname correctly' do
        year, dirname, file = helper.parse_url('/diary/1995/198508-camp/', 'file.jpg')
        expect(year).to eq('1995')
        expect(dirname).to eq('198508-camp')
        expect(file).to eq('file.jpg')
      end

      it 'extracts year and dirname correctly with relative path #1' do
        year, dirname, file = helper.parse_url('/diary/2004/0508-camp/', '../1223-test/file.jpg')
        expect(year).to eq('2004')
        expect(dirname).to eq('1223-test')
        expect(file).to eq('file.jpg')
      end

      it 'extracts year and dirname correctly with relative path #2' do
        year, dirname, file = helper.parse_url('/diary/1995/198508-camp/', '../../2001/1223-test/file.jpg')
        expect(year).to eq('2001')
        expect(dirname).to eq('1223-test')
        expect(file).to eq('file.jpg')
      end
    end
  end

  describe '#dropbox_url' do
    context 'when image exists' do
      it 'returns the correct URL' do
        url = helper.dropbox_url(year: '1995', dirname: '198508-camp', basename: '001_001', ext: 'jpg')
        expect(url).to eq(app.data.image['1995']['198508-camp']['001_001.jpg'])
      end
    end

    context 'when image does not exist' do
      it 'returns the error image' do
        url = helper.dropbox_url(year: '1995', dirname: '198508-camp', basename: 'nonexistent', ext: 'jpg')
        expect(url).to eq(app.data.site.error_image)
      end
    end

    context 'when year or dirname does not exist' do
      it 'returns the error image' do
        url = helper.dropbox_url(year: '2024', dirname: 'nonexistent', basename: '001_001', ext: 'jpg')
        expect(url).to eq(app.data.site.error_image)
      end
    end
  end

  describe '#image' do
    it 'generates an image link with the correct URL and class' do
      url = app.data.image['1995']['198508-camp']['001_001.jpg']
      result = helper.image('001_001')
      expect(result).to eq("<a href=\"#{url}\" class=\"image swipe\"><img src=\"#{url}\" height=\"#{app.data.site.thumbheight}\" /></a>")
    end

    it 'uses the error image when the image does not exist' do
      result = helper.image('nonexistent')
      expect(result).to eq("<a href=\"#{app.data.site.error_image}\" class=\"image swipe\"><img src=\"#{app.data.site.error_image}\" height=\"#{app.data.site.thumbheight}\" /></a>")
    end
  end

  describe '#simage' do
    context 'with default height' do
      it 'generates an image tag without height attribute' do
        url = app.data.image['1995']['198508-camp']['001_001.jpg']
        result = helper.simage('001_001')
        expect(result).to eq("<img src=\"#{url}\" height=\"#{app.data.site.simageheight}\" />")
      end
    end

    context 'with specified height' do
      it 'generates an image tag with height attribute' do
        url = app.data.image['1995']['198508-camp']['001_001.jpg']
        result = helper.simage('001_001', height: 300)
        expect(result).to eq("<img src=\"#{url}\" height=\"300\" />")
      end
    end
  end

  describe '#movie' do
    it 'generates a video link with the correct URL and class' do
      # Mock the dropbox_url method for video and thumbnail
      allow(helper).to receive(:dropbox_url).with(year: '1995', dirname: '198508-camp', basename: 'img_5678',
                                                  ext: 'mp4').and_return('https://example.com/img_5678.mp4')

      result = helper.movie('img_5678')
      expect(result).to eq('<a href="https://example.com/img_5678.mp4" class="video swipe"><img src="https://example.com/img_5678.jpg" height="200" /></a>')
    end
  end

  describe '#audio' do
    it 'generates an audio tag with the correct source' do
      # Mock the dropbox_url method for audio
      allow(helper).to receive(:dropbox_url).with(year: '1995', dirname: '198508-camp', basename: 'img_5678',
                                                  ext: 'm4a').and_return('https://example.com/img_9012.m4a')

      result = helper.audio('img_5678')
      expect(result).to eq('<audio controls><source src="https://example.com/img_9012.m4a" type="audio/aac"></audio>')
    end
  end

  describe '#static_to' do
    it 'generates a link to a static file' do
      # Mock dropbox_url
      allow(helper).to receive(:dropbox_url).with(year: '1995', dirname: '198508-camp', basename: 'document',
                                                  ext: 'pdf').and_return('https://example.com/document.pdf')

      result = helper.static_to('document.pdf', 'Download PDF')
      expect(result).to eq('<a href="https://example.com/document.pdf" class="">Download PDF</a>')
    end
  end
end
