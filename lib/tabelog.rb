#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'json'
require 'unicode_utils'

USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) ' \
             'AppleWebKit/537.36 (KHTML, like Gecko) ' \
             'Chrome/77.0.3864.0 Safari/537.36'

def tabelog(url)
  raise 'URL parameter is missing' if url.nil? || url.empty?

  html = fetch_tabelog_html(url)
  doc = Nokogiri::HTML(html)
  info = parse_tabelog_info(doc)

  return 'Could not find the information table on the page.' if info.empty?

  format_tabelog_output(info, url)
end

def fetch_tabelog_html(url)
  URI.parse(url).open('User-Agent' => USER_AGENT).read
end

def parse_tabelog_info(doc)
  table = doc.at_css('table.rstinfo-table__table tbody')
  return {} unless table

  table.css('tr').each_with_object({}) do |row, info|
    header_node = row.at_css('th')
    next unless header_node

    header = header_node.text.strip
    value = extract_tabelog_row_value(row, header)&.text&.strip
    info[header] = value if value
  end
end

def extract_tabelog_row_value(row, header)
  case header
  when /住所/
    row.at_css('td p.rstinfo-table__address') || row.at_css('td')
  when /お問い合わせ/
    row.at_css('td strong.rstinfo-table__tel-num') || row.at_css('td')
  else
    row.at_css('td')
  end
end

def format_tabelog_output(info, url)
  shop_name = info['店名'] || 'N/A'

  address_key = info.keys.find { |k| k.include?('住所') }
  address = address_key ? UnicodeUtils.nfkd(info[address_key]) : 'N/A'

  contact_key = info.keys.find { |k| k.include?('お問い合わせ') }
  contact = contact_key ? UnicodeUtils.nfkd(info[contact_key]) : ''

  contact_line = contact.to_s.empty? ? '' : "\n#{contact}"

  <<~HTML
    <pre class="address">
    <a href="#{url}">#{shop_name}</a>
    #{address}#{contact_line}
    </pre>
  HTML
end

# This block handles command-line execution, mirroring the Python script's `if __name__ == "__main__":`
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    warn "Usage: #{$PROGRAM_NAME} <url>"
    exit 1
  end

  puts tabelog(ARGV[0])
end
