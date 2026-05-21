require 'spec_helper'
require_relative '../../helpers/page_metadata_helpers'
require_relative '../../helpers/daylog_helpers'

RSpec.describe DaylogHelpers do
  let(:helper) do
    Class.new do
      include PageMetadataHelpers
      include DaylogHelpers
    end.new
  end

  before do
    allow(helper).to receive(:data).and_return(app.data)
    allow(helper).to receive(:link_to) do |text, url, options = {}|
      target = options[:target] ? " target=\"#{options[:target]}\"" : ''
      "<a href=\"#{url}\"#{target}>#{text}</a>"
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
    describe '#process_amazon' do
      let(:amazon_line_input) { '「<a href="https://www.amazon.co.jp/dp/B0FCJ7H8KD/">オルクセン王国史～野蛮なオークの国は、如何にして平和なエルフの国を焼き払うに至ったか～ 5</a>」、樽見京一郎、一二三書房' }
      let(:expected_asid) { 'your-test-asid' }

      before do
        allow(app.data.site).to receive(:asid).and_return(expected_asid)
      end

      it 'appends Amazon ASID and ref=nosim to the Amazon URL, preserving quotes' do
        processed_line = helper.send(:process_amazon, amazon_line_input)
        expected_url_part = "href=\"https://www.amazon.co.jp/dp/B0FCJ7H8KD/ref=nosim?tag=#{expected_asid}\""
        expect(processed_line).to include(expected_url_part)
      end

      it 'does not modify lines without an Amazon URL' do
        line = 'This is a plain line without any amazon link.'
        expect(helper.send(:process_amazon, line)).to eq(line)
      end

      it 'does not modify lines with a non-amazon URL' do
        line = 'This is a link to <a href="https://example.com">example.com</a>'
        expect(helper.send(:process_amazon, line)).to eq(line)
      end
    end
  end
end
