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

    nav = '<nav class="prev_next" aria-label="Diary navigation">'
    if prev_page
      nav += nav_link_html(
        direction: 'prev',
        url: prev_page.url,
        eyebrow: 'Previous',
        label: '&laquo; prev'
      )
    end
    nav += '<span class="prev_next-divider" aria-hidden="true"></span>' if prev_page && next_page
    if next_page
      nav += nav_link_html(
        direction: 'next',
        url: next_page.url,
        eyebrow: 'Next',
        label: 'next &raquo;'
      )
    end
    nav += '</nav>'
    nav
  end

  def nav_link_html(direction:, url:, eyebrow:, label:)
    "<a class=\"prev_next-link #{direction}\" href=\"#{url}\">" \
      "<span class=\"prev_next-eyebrow\">#{eyebrow}</span>" \
      "<span class=\"prev_next-label\">#{label}</span></a>"
  end
end
