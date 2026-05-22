require 'spec_helper'
require_relative '../../helpers/embed_helpers'

RSpec.describe EmbedHelpers do
  let(:helper) { Class.new { include EmbedHelpers }.new }
  let(:current_page) do
    double(
      'current_page',
      data: double(
        'page_data',
        note_url: 'https://note.com/example',
        qiita_url: 'https://qiita.com/example'
      )
    )
  end

  before do
    allow(helper).to receive(:data).and_return(app.data)
    allow(helper).to receive(:current_page).and_return(current_page)
    allow(helper).to receive(:link_to) do |text, url, _options = {}|
      "<a href=\"#{url}\">#{text}</a>"
    end
  end

  describe '#qiita' do
    it 'returns note div with Qiita link' do
      result = helper.qiita
      expect(result).to include('本ドキュメントは')
      expect(result).to include('Qiita記事')
      expect(result).to include('https://qiita.com/example')
    end
  end

  describe '#note' do
    it 'returns note div with note link' do
      result = helper.note
      expect(result).to include('本ドキュメントは')
      expect(result).to include('note記事')
      expect(result).to include('https://note.com/example')
    end
  end

  describe '#amazon' do
    it 'generates an Amazon link with the correct URL and affiliate ID' do
      result = helper.amazon('Book Title', '1234567890', 'imagepath')
      expect(result).to eq("<div class=\"embeded\">\n  <div class=\"amazon\">\n    <div class=\"amazon-image\"><a href=\"https://www.amazon.co.jp/dp/1234567890/daydreaonthen-22\"><img border=\"0\" src=\"https://m.media-amazon.com/images/I/imagepath._AC_SL400_.jpg\" height=200></a></a></div>\n    <div class=\"amazon-info\"><a href=\"https://www.amazon.co.jp/dp/1234567890/daydreaonthen-22\">Book Title</a></div>\n  </div>\n</div>\n")
    end
  end
end
