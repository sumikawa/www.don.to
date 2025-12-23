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

  describe '#thisyear' do
    it 'returns the latest year from diary directories' do
      allow(Dir).to receive(:glob).with('source/diary/[0-9]*').and_return(['source/diary/2023', 'source/diary/2025', 'source/diary/2024'])
      expect(helper.thisyear).to eq(2025)
    end
  end

  describe '#gen_date' do
    it 'returns date string from URL' do
      expect(helper.gen_date).to eq('2025-02-03')
    end
  end

  describe '#qiita' do
    it 'returns note div with Qiita link' do
      result = helper.qiita('https://qiita.com/example')
      expect(result).to include('本ドキュメントは')
      expect(result).to include('Qiita記事')
      expect(result).to include('https://qiita.com/example')
    end
  end

  describe '#note' do
    it 'returns note div with note link' do
      result = helper.note('https://note.com/example')
      expect(result).to include('本ドキュメントは')
      expect(result).to include('note記事')
      expect(result).to include('https://note.com/example')
    end
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
      result = helper.amazon('Book Title', '1234567890', 'imagepath')
      expect(result).to eq("<div class=\"embeded\">
  <div class=\"amazon\">
    <div class=\"amazon-image\"><a href=\"https://www.amazon.co.jp/dp/1234567890/daydreaonthen-22\"><img border=\"0\" src=\"https://m.media-amazon.com/images/I/imagepath._AC_SL400_.jpg\" height=200></a></a></div>
    <div class=\"amazon-info\"><a href=\"https://www.amazon.co.jp/dp/1234567890/daydreaonthen-22\">Book Title</a></div>
  </div>
</div>\n")
    end
  end

  describe '#rend_daylog' do
    it 'renders daylog entries for the specified year' do
      result = helper.rend_daylog(2025)
      expect(result).to include('<dt>2025/10/29: 「<a href="https://www.amazon.co.jp/dp/B08XQ65HP7/ref=nosim?tag=daydreaonthen-22">かがみの孤城 上</a>」、辻村深月、ポプラ文庫</dt>')
      expect(result).to include("<dt>2025/10/10: サイト内検索ライブラリを変更</dt>\n<dd>\t<a href=\"https://www.algolia.com/\">Algolia</a>から<a href=\"https://pagefind.app/\">pagefind</a>に変えた</dd>")
      expect(result).not_to include('2024')
    end
  end

  describe '#gen_link' do
    context 'with regular filename' do
      it 'generates a link with date information' do
        result = helper.gen_link('source/diary/2025/0203-test.html.md.erb', 'Miyakojima Trip', false)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/2025/0203-test.html">Miyakojima Trip</a></dt><dd></dd>')
      end
    end

    context 'with secret filename' do
      it 'adds secret message to the link' do
        result = helper.gen_link('source/diary/2025/0203-secret.html.md.erb', 'Secret Trip', false)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/2025/0203-secret.html">Secret Trip</a> (要パスワード)</dt><dd></dd>')
      end
    end

    context 'with blank target' do
      it 'adds target="_blank" to the link' do
        result = helper.gen_link('source/diary/2025/0203-test.html.md.erb', 'Miyakojima Trip', true)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/2025/0203-test.html" target="_blank">Miyakojima Trip</a></dt><dd></dd>')
      end
    end

    context 'with empty title' do
      it 'uses default title' do
        result = helper.gen_link('source/diary/2025/0203-test.html.md.erb', '', false)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/2025/0203-test.html">no title</a></dt><dd></dd>')
      end
    end

    context 'with different date formats' do
      it 'handles YYYYMM format' do
        result = helper.gen_link('source/diary/2025/02-test.html.md.erb', 'Miyakojima Trip', false)
        expect(result).to eq('<dt>2025/02/??: <a href="/diary/2025/02-test.html">Miyakojima Trip</a></dt><dd></dd>')
      end

      it 'handles YYYY/MMDD format' do
        result = helper.gen_link('source/diary/2025/0203-test.html.md.erb', 'Miyakojima Trip', false)
        expect(result).to eq('<dt>2025/02/03: <a href="/diary/2025/0203-test.html">Miyakojima Trip</a></dt><dd></dd>')
      end

      it 'handles unknown format' do
        result = helper.gen_link('source/diary/miyakojima.html.md.erb', 'Miyakojima Trip', false)
        expect(result).to eq('<dt>UNKNOWN: <a href="/diary/miyakojima.html">Miyakojima Trip</a></dt><dd></dd>')
      end
    end
  end

  describe 'private methods' do
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

    describe '#_process_amazon' do
      let(:amazon_line_input) { "「<a href=\"https://www.amazon.co.jp/dp/B0FCJ7H8KD/\">オルクセン王国史～野蛮なオークの国は、如何にして平和なエルフの国を焼き払うに至ったか～ 5</a>」、樽見京一郎、一二三書房" }
      let(:expected_asid) { 'your-test-asid' }

      before do
        # Stub the asid for this test context
        allow(app.data.site).to receive(:asid).and_return(expected_asid)
      end

      it 'appends Amazon ASID and ref=nosim to the Amazon URL, preserving quotes' do
        processed_line = helper.send(:_process_amazon, amazon_line_input)
        expected_url_part = "href=\"https://www.amazon.co.jp/dp/B0FCJ7H8KD/ref=nosim?tag=#{expected_asid}\""
        expect(processed_line).to include(expected_url_part)
      end

      it 'does not modify lines without an Amazon URL' do
        line = "This is a plain line without any amazon link."
        expect(helper.send(:_process_amazon, line)).to eq(line)
      end

      it 'does not modify lines with a non-amazon URL' do
        line = "This is a link to <a href=\"https://example.com\">example.com</a>"
        expect(helper.send(:_process_amazon, line)).to eq(line)
      end
    end
  end
end
