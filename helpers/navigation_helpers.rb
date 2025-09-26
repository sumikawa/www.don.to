module NavigationHelpers
  def diary_nav(current_page, sitemap)
    prev_page = nil
    next_page = nil

    # 現在のページのパスが diary/YYYY/ の形式にマッチする場合にのみ実行
    if matches = current_page.path.match(%r{diary/((19|20)\d{2})/.+})
      year = matches[1]
      # sitemap から同じ年（year）のディレクトリ内のページを取得
      pages = sitemap.resources.select do |res|
        res.path.start_with?("diary/#{year}/") && res.ext == '.html'
      end.sort_by { |res| res.path } # ファイル名でソート

      # 現在のページのインデックスを探す
      current_index = pages.find_index { |p| p.path == current_page.path }

      if current_index
        prev_page = pages[current_index - 1] if current_index > 0
        next_page = pages[current_index + 1] if current_index < pages.size - 1
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
