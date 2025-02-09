require 'spec_helper'
require_relative '../../lib/link_helpers'

include LinkHelpers

RSpec.describe do
  describe 'parse url' do
    it 'with /' do
      year, dirname, basename = parse_url('img_1234', '/diary/2025/0203-miyakojima/')
      expect(year).to eq('2025')
      expect(dirname).to eq('0203-miyakojima')
      expect(basename).to eq('img_1234')
    end

    it 'with .html' do
      year, dirname, basename = parse_url('img_1234', '/diary/2025/0203-miyakojima.html')
      expect(year).to eq('2025')
      expect(dirname).to eq('0203-miyakojima')
      expect(basename).to eq('img_1234')
    end
  end

  # describe 'get dropbox url' do
  #   it 'miyakojima' do
  #     dropbox_url2(year: '2025', dirname: '0203-miyakojima', basename: 'img_0579', ext: 'jpg')
  #   end
  # end
end
