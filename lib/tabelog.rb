#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'json'

USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3864.0 Safari/537.36'

def tabelog(url)
  raise 'URL parameter is missing' if url.nil? || url.empty?

  html = URI.open(url, 'User-Agent' => USER_AGENT).read
  doc = Nokogiri::HTML(html)
  table = doc.at_css('table.rstinfo-table__table tbody')

  if table
    info = {}
    table.css('tr').each do |row|
      header_node = row.at_css('th')
      next unless header_node

      header = header_node.text.strip

      value_node = case header
                   when /住所/
                     row.at_css('td p.rstinfo-table__address') || row.at_css('td')
                   when /お問い合わせ/
                     row.at_css('td strong.rstinfo-table__tel-num') || row.at_css('td')
                   else
                     row.at_css('td')
                   end

      value = value_node&.text&.strip
      info[header] = value if value
    end

    shop_name = info['店名'] || 'N/A'
    address = info.keys.find { |k| k.include?('住所') }&.then { |k| info[k] } || 'N/A'
    contact = info.keys.find { |k| k.include?('お問い合わせ') }&.then { |k| info[k] } || 'N/A'
    contact = 'N/A' if contact.nil? || contact.empty?

    output_html = <<~HTML
      <pre class="address">
      <a href="#{url}">#{shop_name}</a>
      #{address}#{"\n#{contact}" unless contact == 'N/A'}
      </pre>
    HTML

    output_html.strip.gsub("\n\n", "\n")
  else
    'Could not find the information table on the page.'
  end
end

# This block handles command-line execution, mirroring the Python script's `if __name__ == "__main__":`
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    warn "Usage: #{$PROGRAM_NAME} <url>"
    exit 1
  end

  puts tabelog(ARGV[0])
end
