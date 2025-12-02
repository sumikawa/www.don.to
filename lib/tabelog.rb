#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'json'

# This function is designed to be compatible with a serverless environment
# like AWS Lambda, while also being executable from the command line for testing.
# The _context parameter is unused but included for lambda compatibility.
def tabelog(url)
  result_message = ''

  if url.nil? || url.empty?
    raise 'URL parameter is missing'
  end

  html = URI.open(url, 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3864.0 Safari/537.36').read
  doc = Nokogiri::HTML(html)
  table = doc.at_css('table.rstinfo-table__table tbody')

  if table
    table.css('br').each(&:remove)
    list = table.text.split("\n").map(&:strip).reject(&:empty?)

    shop_name_index = list.index('店名')
    address_index = list.index('住所')
    contact_index = list.index('予約・ お問い合わせ') || list.index('お問い合わせ')

    shop_name = shop_name_index ? list[shop_name_index + 1] : 'N/A'
    address = address_index ? list[address_index + 1] : 'N/A'
    contact = contact_index ? list[contact_index + 1] : 'N/A'

    output_html = <<~HTML
            <pre class="address">
            <a href="#{url}">#{shop_name}</a>
            #{address}#{"\n#{contact}" unless contact == 'N/A'}
            </pre>
          HTML

    result_message = output_html.strip.gsub("\n\n", "\n")
  else
    result_message = 'Could not find the information table on the page.'
  end

  output_html
end

# This block handles command-line execution, mirroring the Python script's `if __name__ == "__main__":`
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    warn "Usage: #{$PROGRAM_NAME} <url>"
    exit 1
  end

  puts tabelog(ARGV[0])
end
