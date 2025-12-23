# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/tabelog'

RSpec.describe '#tabelog' do
  let(:valid_url) { 'https://tabelog.com/kanagawa/A1401/A140101/14079506/' }
  # Load the test data from an external file
  let(:tabelog_html) { File.read(File.join(__dir__, 'tabelog_test.html')) }

  # These small, specific HTML snippets are kept for testing edge cases.
  let(:html_no_contact) do
    <<~HTML
      <html>
        <body>
          <table class="rstinfo-table__table">
            <tbody>
              <tr><th>店名</th><td><p>サンプルレストラン</p></td></tr>
              <tr><th>住所</th><td><p class="rstinfo-table__address">東京都サンプル区サンプル 1-2-3</p></td></tr>
              <tr><th>お問い合わせ</th><td><strong class="rstinfo-table__tel-num"></strong></td></tr>
            </tbody>
          </table>
        </body>
      </html>
    HTML
  end
  let(:html_no_table) { '<html><body><h1>No table here</h1></body></html>' }

  context 'with a valid URL and full information from file' do
    it 'returns formatted address HTML' do
      uri_mock = double('uri_mock')
      allow(URI).to receive(:parse).with(valid_url).and_return(uri_mock)
      allow(uri_mock).to receive(:open).with('User-Agent' => USER_AGENT).and_return(StringIO.new(tabelog_html))

      expected_html = <<~HTML.strip
        <pre class="address">
        <a href="#{valid_url}">COMEDOR DE MARGARITA MODERN MEXICANO</a>
        神奈川県横浜市西区南幸1-1‐1 ニュウマン横浜店 9F
        045-900-0320
        </pre>
      HTML

      expect(tabelog(valid_url)).to eq(expected_html)
    end
  end

  context 'when contact information is missing' do
    it 'returns formatted HTML without the contact line' do
      uri_mock = double('uri_mock')
      allow(URI).to receive(:parse).with(valid_url).and_return(uri_mock)
      allow(uri_mock).to receive(:open).with('User-Agent' => USER_AGENT).and_return(StringIO.new(html_no_contact))

      expected_html = <<~HTML.strip
        <pre class="address">
        <a href="#{valid_url}">サンプルレストラン</a>
        東京都サンプル区サンプル 1-2-3
        </pre>
      HTML

      expect(tabelog(valid_url)).to eq(expected_html)
    end
  end

  context 'when the information table is not on the page' do
    it 'returns an error message' do
      uri_mock = double('uri_mock')
      allow(URI).to receive(:parse).with(valid_url).and_return(uri_mock)
      allow(uri_mock).to receive(:open).with('User-Agent' => USER_AGENT).and_return(StringIO.new(html_no_table))
      expect(tabelog(valid_url)).to eq('Could not find the information table on the page.')
    end
  end

  context 'with invalid arguments' do
    it 'raises an error if URL is nil' do
      expect { tabelog(nil) }.to raise_error('URL parameter is missing')
    end

    it 'raises an error if URL is empty' do
      expect { tabelog('') }.to raise_error('URL parameter is missing')
    end
  end
end
