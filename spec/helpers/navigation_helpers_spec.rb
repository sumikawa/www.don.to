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

  context 'with a diary page in the middle' do
    let(:current_page) { pages[1] }
    it 'returns links to both prev and next pages' do
      nav = helper.diary_nav(current_page, sitemap)
      expect(nav).to include('<a href="/diary/2023/0101-foo.html">&laquo; prev</a>')
      expect(nav).to include('<a href="/diary/2023/0103-baz.html">next &raquo;</a>')
      expect(nav).to include('<span style="margin: 0 1em;">|</span>')
    end
  end

  context 'with the first diary page' do
    let(:current_page) { pages[0] }
    it 'returns a link to only the next page' do
      nav = helper.diary_nav(current_page, sitemap)
      expect(nav).not_to include('&laquo; prev</a>')
      expect(nav).to include('<a href="/diary/2023/0102-bar.html">next &raquo;</a>')
      expect(nav).not_to include('<span style="margin: 0 1em;">|</span>')
    end
  end

  context 'with the last diary page' do
    let(:current_page) { pages[2] }
    it 'returns a link to only the prev page' do
      nav = helper.diary_nav(current_page, sitemap)
      expect(nav).to include('<a href="/diary/2023/0102-bar.html">&laquo; prev</a>')
      expect(nav).not_to include('next &raquo;</a>')
      expect(nav).not_to include('<span style="margin: 0 1em;">|</span>')
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
