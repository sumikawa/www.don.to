require 'spec_helper'
require_relative '../../helpers/page_metadata_helpers'

RSpec.describe PageMetadataHelpers do
  let(:helper) { Class.new { include PageMetadataHelpers }.new }

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
    allow(helper).to receive(:data).and_return(app.data)
    allow(helper).to receive(:current_page).and_return(current_page)
  end

  describe '#gen_date' do
    it 'returns date string from URL' do
      expect(helper.gen_date).to eq('2025-02-03')
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

  describe '#current_page_tags' do
    it 'returns normalized tags from a comma separated string' do
      allow(current_page.data).to receive(:tags).and_return('travel, secret, family ')
      expect(helper.current_page_tags).to eq(%w[travel secret family])
    end

    it 'returns normalized tags from an array' do
      allow(current_page.data).to receive(:tags).and_return([' travel ', :secret, ''])
      expect(helper.current_page_tags).to eq(%w[travel secret])
    end

    it 'returns an empty array when tags are missing' do
      allow(current_page.data).to receive(:tags).and_return(nil)
      expect(helper.current_page_tags).to eq([])
    end
  end

  describe '#secret_page?' do
    it 'returns true when the page has a secret tag' do
      allow(current_page.data).to receive(:tags).and_return('travel, secret')
      expect(helper.secret_page?).to be(true)
    end

    it 'returns false when the page does not have a secret tag' do
      allow(current_page.data).to receive(:tags).and_return('travel, family')
      expect(helper.secret_page?).to be(false)
    end
  end

  describe '#secret_password_sha256' do
    it 'returns a normalized SHA-256 digest when configured' do
      allow(app.data.site).to receive(:secret_password_sha256).and_return(' ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890 ')
      expect(helper.secret_password_sha256).to eq('abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890')
    end

    it 'returns nil when the configured value is invalid' do
      allow(app.data.site).to receive(:secret_password_sha256).and_return('not-a-digest')
      expect(helper.secret_password_sha256).to be_nil
    end
  end

  describe 'private methods' do
    describe '#extract_date_string' do
      it 'extracts date from various string formats' do
        expect(helper.send(:extract_date_string, '/diary/1995/198508-camp/')).to eq('1985/08')
        expect(helper.send(:extract_date_string, '/diary/2025/0101-test/')).to eq('2025/01/01')
        expect(helper.send(:extract_date_string, 'source/diary/2025/0101-test.html.md.erb')).to eq('2025/01/01')
        expect(helper.send(:extract_date_string, 'source/diary/2025/01-test.html.md.erb')).to eq('2025/01/??')
        expect(helper.send(:extract_date_string, '/diary/2025/')).to eq('2025年')
        expect(helper.send(:extract_date_string, '/diary/2025.html')).to eq('2025年')
        expect(helper.send(:extract_date_string, '/diary/1995/')).to eq('1995年以前')
        expect(helper.send(:extract_date_string, 'foobar')).to be_nil
      end
    end
  end
end
