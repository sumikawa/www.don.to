# frozen_string_literal: true

module PageMetadataHelpers
  def gen_date
    url = current_page.url
    date_str = extract_date_string(url) || '0000-00-00'
    date_str.gsub('/', '-')
  end

  def gen_title
    url = current_page.url
    date_str = extract_date_string(url)
    title = current_page.data.title || data.site.notitle

    if date_str.nil?
      title
    elsif date_str.end_with?('年') || date_str.end_with?('以前')
      date_str
    else
      "#{date_str}: #{title}"
    end
  end

  def current_page_tags
    raw_tags = current_page.data.tags
    return [] if raw_tags.nil?

    case raw_tags
    when String
      raw_tags.split(',').map(&:strip).reject(&:empty?)
    when Array
      raw_tags.map(&:to_s).map(&:strip).reject(&:empty?)
    else
      []
    end
  end

  def secret_page?
    current_page_tags.include?('secret')
  end

  def secret_password_sha256
    value = data.site.secret_password_sha256
    return nil if value.nil?

    normalized = value.to_s.strip.downcase
    normalized.match?(/\A\h{64}\z/) ? normalized : nil
  end

  private

  def extract_date_string(str)
    case str
    when %r{/diary/1995/(\d\d\d\d)(\d\d)(\d\d)-\w+}
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/#{::Regexp.last_match(3)}"
    when %r{/diary/1995/(\d\d\d\d)(\d\d)-\w+}
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}"
    when /1995/
      '1995年以前'
    when %r{/(\d\d\d\d)/(\d\d)(\d\d)-\w+}
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/#{::Regexp.last_match(3)}"
    when %r{/(\d\d\d\d)/(\d\d)-\w+}
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/??"
    when %r{(\d\d\d\d)(/|\.html$)}
      "#{::Regexp.last_match(1)}年"
    end
  end
end
