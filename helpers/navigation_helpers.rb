module NavigationHelpers
  def diary_nav(current_page, sitemap)
    prev_page, next_page = find_prev_next_pages(current_page, sitemap)
    _gen_nav(prev_page, next_page)
  end

  private

  def find_prev_next_pages(current_page, sitemap)
    return [nil, nil] unless current_page.path.match?(%r{diary/(19|20)\d{2}/.+})

    all_pages = _get_all_diary_pages(sitemap)

    current_index = all_pages.find_index { |p| p.path == current_page.path }
    return [nil, nil] unless current_index

    prev_page = all_pages[current_index - 1] if current_index.positive?
    next_page = all_pages[current_index + 1] if current_index < all_pages.size - 1

    [prev_page, next_page]
  end

  def _get_all_diary_pages(sitemap)
    sitemap.resources.select do |res|
      res.path.match?(%r{diary/(19|20)\d{2}/.+}) && res.ext == '.html' && !res.data.draft
    end.sort_by(&:path)
  end

  def _gen_nav(prev_page, next_page)
    return unless prev_page || next_page

    nav = '<nav class="prev_next" style="text-align: center; margin: 1em 0;">'
    nav += "<a href=\"#{prev_page.url}\">&laquo; prev</a>" if prev_page
    nav += '<span style="margin: 0 1em;">|</span>' if prev_page && next_page
    nav += "<a href=\"#{next_page.url}\">next &raquo;</a>" if next_page
    nav += '</nav>'
    nav
  end
end
