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
