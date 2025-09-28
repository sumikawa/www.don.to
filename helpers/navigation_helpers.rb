module NavigationHelpers
  def diary_nav(current_page, sitemap)
    prev_page = nil
    next_page = nil

    # 現在のページが年号ディレクトリ内の記事であるか確認
    if current_page.path.match?(%r{diary/(19|20)\d{2}/.+})
      # すべての年号ディレクトリから記事ページを取得
      all_pages = sitemap.resources.select do |res|
        res.path.match?(%r{diary/(19|20)\d{2}/.+}) && res.ext == '.html' && !res.data.draft
      end.sort_by { |res| res.path } # パスでソート (YYYY/MMDD... 形式なので時系列になる)

      # 全体リストの中から現在のページのインデックスを探す
      current_index = all_pages.find_index { |p| p.path == current_page.path }

      if current_index
        prev_page = all_pages[current_index - 1] if current_index > 0
        next_page = all_pages[current_index + 1] if current_index < all_pages.size - 1
      end
    end

    # ナビゲーションHTMLを構築
    if prev_page || next_page
      nav = '<nav class="prev_next" style="text-align: center; margin: 1em 0;">'
      if prev_page
        nav += "<a href=\"#{prev_page.url}\">&laquo; prev</a>"
      end
      if prev_page && next_page
        nav += '<span style="margin: 0 1em;">|</span>'
      end
      if next_page
        nav += "<a href=\"#{next_page.url}\">next &raquo;</a>"
      end
      nav += '</nav>'
      return nav
    end

    return ''
  end
end
