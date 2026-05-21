require 'spec_helper'
require_relative '../../helpers/navigation_helpers'

class TestHelper
  include NavigationHelpers
end

PageData = Struct.new(:draft)
Page = Struct.new(:path, :ext, :data, :url)
Sitemap = Struct.new(:resources)

RSpec.describe NavigationHelpers do
  let(:helper) { TestHelper.new }

  let(:sitemap) { Sitemap.new(pages) }

  let(:pages) do
    [
      Page.new('diary/2023/0101-foo.html', '.html', PageData.new(false), '/diary/2023/0101-foo.html'),
      Page.new('diary/2023/0102-bar.html', '.html', PageData.new(false), '/diary/2023/0102-bar.html'),
      Page.new('diary/2023/0103-baz.html', '.html', PageData.new(false), '/diary/2023/0103-baz.html'),
      Page.new('diary/2023/0104-draft.html', '.html', PageData.new(true), '/diary/2023/0104-draft.html'),
      Page.new('other/page.html', '.html', PageData.new(false), '/other/page.html')
    ]
  end

  describe '#diary_nav' do
    context 'with a diary page in the middle' do
      let(:current_page) { pages[1] }
      it 'returns links to both prev and next pages' do
        nav = helper.diary_nav(current_page, sitemap)
        expect(nav).to include('<nav class="prev_next" aria-label="Diary navigation">')
        expect(nav).to include('<a class="prev_next-link prev" href="/diary/2023/0101-foo.html"><span class="prev_next-eyebrow">Previous</span><span class="prev_next-label">&laquo; prev</span></a>')
        expect(nav).to include('<a class="prev_next-link next" href="/diary/2023/0103-baz.html"><span class="prev_next-eyebrow">Next</span><span class="prev_next-label">next &raquo;</span></a>')
        expect(nav).to include('<span class="prev_next-divider" aria-hidden="true"></span>')
      end
    end

    context 'with the first diary page' do
      let(:current_page) { pages[0] }
      it 'returns a link to only the next page' do
        nav = helper.diary_nav(current_page, sitemap)
        expect(nav).not_to include('class="prev_next-link prev"')
        expect(nav).to include('<a class="prev_next-link next" href="/diary/2023/0102-bar.html"><span class="prev_next-eyebrow">Next</span><span class="prev_next-label">next &raquo;</span></a>')
        expect(nav).not_to include('class="prev_next-divider"')
      end
    end

    context 'with the last diary page' do
      let(:current_page) { pages[2] }
      it 'returns a link to only the prev page' do
        nav = helper.diary_nav(current_page, sitemap)
        expect(nav).to include('<a class="prev_next-link prev" href="/diary/2023/0102-bar.html"><span class="prev_next-eyebrow">Previous</span><span class="prev_next-label">&laquo; prev</span></a>')
        expect(nav).not_to include('class="prev_next-link next"')
        expect(nav).not_to include('class="prev_next-divider"')
      end
    end

    context 'with a non-diary page' do
      let(:current_page) { pages[4] }
      it 'returns nil' do
        nav = helper.diary_nav(current_page, sitemap)
        expect(nav).to be_nil
      end
    end

    context 'with a draft page' do
      let(:current_page) { pages[3] }
      it 'returns nil because draft pages are not in the list' do
        nav = helper.diary_nav(current_page, sitemap)
        expect(nav).to be_nil
      end
    end
  end

  describe '#find_prev_next_pages' do
    it 'returns prev and next pages for middle page' do
      prev_page, next_page = helper.send(:find_prev_next_pages, pages[1], sitemap)
      expect(prev_page).to eq(pages[0])
      expect(next_page).to eq(pages[2])
    end

    it 'returns nil and next for first page' do
      prev_page, next_page = helper.send(:find_prev_next_pages, pages[0], sitemap)
      expect(prev_page).to be_nil
      expect(next_page).to eq(pages[1])
    end

    it 'returns prev and nil for last page' do
      prev_page, next_page = helper.send(:find_prev_next_pages, pages[2], sitemap)
      expect(prev_page).to eq(pages[1])
      expect(next_page).to be_nil
    end
  end

  describe '#_get_all_diary_pages' do
    it 'returns only diary pages excluding drafts' do
      result = helper.send(:_get_all_diary_pages, sitemap)
      expect(result.size).to eq(3)
      expect(result).not_to include(pages[3])
      expect(result).not_to include(pages[4])
    end
  end

  describe '#_gen_nav' do
    it 'generates nav with both prev and next' do
      nav = helper.send(:_gen_nav, pages[0], pages[1])
      expect(nav).to include('&laquo; prev')
      expect(nav).to include('next &raquo;')
    end

    it 'generates nav with only prev' do
      nav = helper.send(:_gen_nav, pages[0], nil)
      expect(nav).to include('&laquo; prev')
      expect(nav).not_to include('next &raquo;')
    end

    it 'generates nav with only next' do
      nav = helper.send(:_gen_nav, nil, pages[1])
      expect(nav).not_to include('&laquo; prev')
      expect(nav).to include('next &raquo;')
    end

    it 'returns nil when both are nil' do
      nav = helper.send(:_gen_nav, nil, nil)
      expect(nav).to be_nil
    end
  end
end
