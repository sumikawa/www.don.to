# frozen_string_literal: true

module CustomHelpers
  def localhost?
    if `hostname`.strip =~ /mbair/
      true
    else
      false
    end
  end

  def thisyear
    Dir.glob('source/diary/[0-9]*').max.gsub(/[^0-9]/, '').to_i
  end

  def gen_date
    url = current_page.url
    date_str = _extract_date_string(url) || '0000-00-00'
    date_str.gsub('/', '-')
  end

  def gen_title
    url = current_page.url
    date_str = _extract_date_string(url)
    title = current_page.data.title || data.site.notitle

    if date_str.nil?
      title
    elsif date_str.end_with?('年') || date_str.end_with?('以前')
      date_str
    else
      "#{date_str}: #{title}"
    end
  end

  # Generates an Amazon link
  def amazon(title, id)
    link_to(title, "https://www.amazon.co.jp/dp/#{id}/#{data.site.asid}")
  end

  # Renders the daylog for a given year
  def rend_daylog(year)
    data.daylog.each_with_object([]) do |item, result|
      entry = case item
              when String
                _process_daylog_string(item, year)
              when Hash
                _process_daylog_hash(item, year)
              end
      result << entry if entry
    end
  end

  # Generates a link to a diary entry
  def gen_link(filename, title, blanks)
    secret = filename =~ /secret/ ? " #{data.site.secretmes}" : ''
    target = blanks ? { target: '_blank' } : {}
    title = data.site.notitle if title == ''
    date = _extract_date_string(filename) || 'UNKNOWN'
    dir = filename.sub(/^source/, '').sub('.md.erb', '')
    "<dt>#{date}: " + link_to(title, dir, target) + "#{secret}</dt><dd></dd>"
  end

  private

  def _process_daylog_string(item, year)
    md = item.match(%r{(\d\d\d\d)/(\d\d)/(\d\d)})
    "<dt>#{item}</dt>" if md && year == md[1].to_i
  end

  def _process_daylog_hash(item, year)
    log = ''
    comment = ''
    item.each do |k, v|
      if k == 'comment'
        comment = "\n<dd>\t#{v}</dd>"
      else
        log = "<dt>#{k}: #{v}</dt>"
      end
    end
    md = log.match(%r{(\d\d\d\d)/(\d\d)/(\d\d)})
    "#{log}#{comment}" if md && year == md[1].to_i
  end

  def _extract_date_string(str)
    case str
    when %r{/diary/1995/(\d\d\d\d)(\d\d)(\d\d)-\w+} # Special cases for oldest pages
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/#{::Regexp.last_match(3)}"
    when %r{/diary/1995/(\d\d\d\d)(\d\d)-\w+} # Special cases for oldest pages
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}"
    when /1995/
      '1995年以前'
    when %r{/(\d\d\d\d)/(\d\d)(\d\d)-\w+} # rubocop:disable Lint/DuplicateBranch
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/#{::Regexp.last_match(3)}"
    when %r{/(\d\d\d\d)/(\d\d)-\w+}
      "#{::Regexp.last_match(1)}/#{::Regexp.last_match(2)}/??"
    when %r{(\d\d\d\d)(/|\.html$)}
      "#{::Regexp.last_match(1)}年"
    end
  end
end
