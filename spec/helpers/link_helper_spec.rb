require 'spec_helper'
require_relative '../../helpers/link_helpers'

RSpec.describe LinkHelpers do
  let(:helper) { Class.new { include LinkHelpers }.new }

  # Mock data object
  let(:data_mock) do
    double('data').tap do |data|
      allow(data).to receive(:site).and_return(
        double('site').tap do |site|
          allow(site).to receive(:error_image).and_return('error.jpg')
          allow(site).to receive(:thumbheight).and_return(200)
          allow(site).to receive(:thumbext).and_return('jpg')
          allow(site).to receive(:videoext).and_return('mp4')
          allow(site).to receive(:audioext).and_return('m4a')
        end
      )

      allow(data).to receive(:image).and_return(
        {
          '2025' => {
            '0203-miyakojima' => {
              'img_1234.jpg' => 'https://example.com/img_1234.jpg',
              'img_5678.mp4' => 'https://example.com/img_5678.mp4',
              'img_9012.m4a' => 'https://example.com/img_9012.m4a'
            }
          }
        }
      )
    end
  end

  # Mock current_page
  let(:current_page) do
    double('current_page').tap do |page|
      allow(page).to receive(:url).and_return('/diary/2025/0203-miyakojima/')
    end
  end

  before do
    # Stub helper methods to use our mocks
    allow(helper).to receive(:data).and_return(data_mock)
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

  describe '#localhost?' do
    context 'when hostname contains mbair' do
      before do
        allow(helper).to receive(:`).with('hostname').and_return("mbair.local\n")
      end

      it 'returns true' do
        expect(helper.localhost?).to be true
      end
    end

    context 'when hostname does not contain mbair' do
      before do
        allow(helper).to receive(:`).with('hostname').and_return("server.example.com\n")
      end

      it 'returns false' do
        expect(helper.localhost?).to be false
      end
    end
  end

  describe '#parse_url' do
    context 'with URL ending in .html' do
      it 'extracts year and dirname correctly' do
        year, dirname = helper.parse_url('/diary/2025/0203-miyakojima.html')
        expect(year).to eq('2025')
        expect(dirname).to eq('0203-miyakojima')
      end
    end

    context 'with URL ending in /' do
      it 'extracts year and dirname correctly' do
        year, dirname = helper.parse_url('/diary/2025/0203-miyakojima/')
        expect(year).to eq('2025')
        expect(dirname).to eq('0203-miyakojima')
      end
    end
  end

  describe '#dropbox_url' do
    context 'when image exists' do
      it 'returns the correct URL' do
        url = helper.dropbox_url(year: '2025', dirname: '0203-miyakojima', basename: 'img_1234', ext: 'jpg')
        expect(url).to eq('https://example.com/img_1234.jpg')
      end
    end

    context 'when image does not exist' do
      it 'returns the error image' do
        url = helper.dropbox_url(year: '2025', dirname: '0203-miyakojima', basename: 'nonexistent', ext: 'jpg')
        expect(url).to eq('error.jpg')
      end
    end

    context 'when year or dirname does not exist' do
      it 'returns the error image' do
        url = helper.dropbox_url(year: '2024', dirname: 'nonexistent', basename: 'img_1234', ext: 'jpg')
        expect(url).to eq('error.jpg')
      end
    end
  end

  describe '#image' do
    it 'generates an image link with the correct URL and class' do
      result = helper.image('img_1234')
      expect(result).to eq('<a href="https://example.com/img_1234.jpg" class="image swipe"><img src="https://example.com/img_1234.jpg" height="200" /></a>')
    end

    it 'uses the error image when the image does not exist' do
      result = helper.image('nonexistent')
      expect(result).to eq('<a href="error.jpg" class="image swipe"><img src="error.jpg" height="200" /></a>')
    end
  end

  describe '#simage' do
    context 'with default height (0)' do
      it 'generates an image tag without height attribute' do
        result = helper.simage('img_1234')
        expect(result).to eq('<img src="https://example.com/img_1234.jpg" />')
      end
    end

    context 'with specified height' do
      it 'generates an image tag with height attribute' do
        result = helper.simage('img_1234', height: 300)
        expect(result).to eq('<img src="https://example.com/img_1234.jpg" height="300" />')
      end
    end

    context 'with specified extension' do
      it 'uses the specified extension' do
        # Mock the dropbox_url method to return a URL with the specified extension
        allow(helper).to receive(:dropbox_url).with(year: '2025', dirname: '0203-miyakojima', basename: 'img_1234',
                                                    ext: 'png').and_return('https://example.com/img_1234.png')

        result = helper.simage('img_1234', ext: 'png')
        expect(result).to eq('<img src="https://example.com/img_1234.png" />')
      end
    end
  end

  describe '#movie' do
    it 'generates a video link with the correct URL and class' do
      # Mock the dropbox_url method for video and thumbnail
      allow(helper).to receive(:dropbox_url).with(year: '2025', dirname: '0203-miyakojima', basename: 'img_5678',
                                                  ext: 'mp4').and_return('https://example.com/img_5678.mp4')
      allow(helper).to receive(:dropbox_url).with(year: '2025', dirname: '0203-miyakojima', basename: 'img_5678',
                                                  ext: 'jpg').and_return('https://example.com/img_5678.jpg')

      result = helper.movie('img_5678')
      expect(result).to eq('<a href="https://example.com/img_5678.mp4" class="video swipe"><img src="https://example.com/img_5678.jpg" height="200" /></a>')
    end
  end

  describe '#audio' do
    it 'generates an audio tag with the correct source' do
      # Mock the dropbox_url method for audio
      allow(helper).to receive(:dropbox_url).with(year: '2025', dirname: '0203-miyakojima', basename: 'img_9012',
                                                  ext: 'm4a').and_return('https://example.com/img_9012.m4a')

      result = helper.audio('img_9012')
      expect(result).to eq('<audio controls><source src="https://example.com/img_9012.m4a.m4a" type="audio/aac"></audio>')
    end
  end

  describe '#static_to' do
    before do
      # Stub puts to avoid output during tests
      allow(helper).to receive(:puts)
    end

    it 'generates a link to a static file' do
      # Mock File methods
      allow(File).to receive(:basename).with('document.pdf', '.*').and_return('document')
      allow(File).to receive(:extname).with('document.pdf').and_return('.pdf')

      # Mock dropbox_url
      allow(helper).to receive(:dropbox_url).with(year: '2025', dirname: '0203-miyakojima', basename: 'document',
                                                  ext: 'pdf').and_return('https://example.com/document.pdf')

      result = helper.static_to('document.pdf', 'Download PDF')
      expect(result).to eq('<a href="https://example.com/document.pdf" class="">Download PDF</a>')
    end
  end
end
