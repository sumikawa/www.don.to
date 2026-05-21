# frozen_string_literal: true

module DaylogHelpers
  def all_daylogs
    data.daylog.values.flatten
  end

  def rend_daylog(year)
    year_data = data.daylog[year.to_s]
    return [] unless year_data

    year_data.each_with_object([]) do |item, result|
      entry = case item
              when String
                process_daylog_string(item, year)
              when Hash
                process_daylog_hash(item, year)
              end
      result << entry if entry
    end
  end

  def gen_link(filename, title, blanks)
    secret = filename =~ /secret/ ? " #{data.site.secretmes}" : ''
    target = blanks ? { target: '_blank' } : {}
    title = data.site.notitle if title == ''
    date = extract_date_string(filename) || 'UNKNOWN'
    dir = filename.sub(/^source/, '').sub('.md.erb', '')
    "<dt>#{date}: " + link_to(title, dir, target) + "#{secret}</dt><dd></dd>"
  end

  private

  def process_amazon(line)
    line.sub(%r{"(https://www.amazon.co.jp/.*/)"}) do
      "\"#{::Regexp.last_match(1)}ref=nosim?tag=#{data.site.asid}\""
    end
  end

  def process_daylog_string(item, year)
    md = item.match(%r{(\d\d\d\d)/(\d\d)/(\d\d)})
    item = process_amazon(item)
    "<dt>#{item}</dt>" if md && year == md[1].to_i
  end

  def process_daylog_hash(item, year)
    log = ''
    comment = ''
    item.each do |k, v|
      v = process_amazon(v)
      if k == 'comment'
        comment = "\n<dd>\t#{v}</dd>"
      else
        log = "<dt>#{k}: #{v}</dt>"
      end
    end
    md = log.match(%r{(\d\d\d\d)/(\d\d)/(\d\d)})
    "#{log}#{comment}" if md && year == md[1].to_i
  end
end
