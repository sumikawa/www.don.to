# frozen_string_literal: true

module EmbedHelpers
  def amazon(title, id, image)
    url = "https://www.amazon.co.jp/dp/#{id}/#{data.site.asid}"
    image_url = "https://m.media-amazon.com/images/I/#{image}._AC_SL400_.jpg"
    img = "<img border=\"0\" src=\"#{image_url}\" height=200></a>"
    <<~HTML.html_safe
      <div class="embeded">
        <div class="amazon">
          <div class="amazon-image">#{link_to(img, url)}</div>
          <div class="amazon-info">#{link_to(title, url)}</div>
        </div>
      </div>
    HTML
  end

  def product(title, url, image_url)
    img = "<img border=\"0\" src=\"#{image_url}\" height=200></a>"
    <<~HTML.html_safe
      <div class="embeded">
        <div class="amazon">
          <div class="amazon-image">#{link_to(img, url)}</div>
          <div class="amazon-info">#{link_to(title, url)}</div>
        </div>
      </div>
    HTML
  end

  def qiita(link)
    "<div class=\"note\">\n本ドキュメントは#{link_to('Qiita記事', link)}のバックアップです。\n</div>"
  end

  def note
    "<div class=\"note\">\n本ドキュメントは#{link_to('note記事', current_page.data.note_url)}のバックアップです。\n</div>"
  end
end
