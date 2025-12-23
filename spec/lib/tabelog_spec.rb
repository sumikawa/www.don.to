# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/tabelog'

RSpec.describe '#tabelog' do
  let(:valid_url) { 'https://tabelog.com/tokyo/A1301/A130101/13002622/' }
  let(:sample_html) do
    <<~HTML
      <html>
        <body>
          <table class="rstinfo-table__table">
            <tbody>
              <tr><th>店名</th><td><p>サンプルレストラン</p></td></tr>
              <tr><th>住所</th><td><p>東京都サンプル区サンプル 1-2-3</p></td></tr>
              <tr><th>予約・ お問い合わせ</th><td>03-1234-5678</td></tr>
            </tbody>
          </table>
        </body>
      </html>
    HTML
  end
  let(:html_no_contact) do
    <<~HTML
      <html>
        <body>
          <table class="rstinfo-table__table">
            <tbody>
              <tr><th>店名</th><td>サンプルレストラン</td></tr>
              <tr><th>住所</th><td>東京都サンプル区サンプル 1-2-3</td></tr>
              <tr><th>お問い合わせ</th><td></td></tr>
            </tbody>
          </table>
        </body>
      </html>
    HTML
  end
  let(:html_no_table) { '<html><body><h1>No table here</h1></body></html>' }

  context 'with a valid URL and full information' do
    it 'returns formatted address HTML' do
      allow(URI).to receive(:open).with(valid_url, 'User-Agent' => USER_AGENT).and_return(StringIO.new(sample_html))

      expected_html = <<~HTML.strip
        <pre class="address">
        <a href="#{valid_url}">サンプルレストラン</a>
        東京都サンプル区サンプル 1-2-3
        03-1234-5678
        </pre>
      HTML

      expect(tabelog(valid_url)).to eq(expected_html)
    end
  end

  context 'when contact information is missing' do
    it 'returns formatted HTML without the contact line' do
      allow(URI).to receive(:open).with(valid_url, 'User-Agent' => USER_AGENT).and_return(StringIO.new(html_no_contact))

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
      allow(URI).to receive(:open).with(valid_url, 'User-Agent' => USER_AGENT).and_return(StringIO.new(html_no_table))
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
