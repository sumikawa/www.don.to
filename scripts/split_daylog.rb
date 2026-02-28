require 'yaml'
require 'fileutils'

daylog_data = YAML.load_file('data/daylog_full.yml')
FileUtils.mkdir_p('data/daylog')

entries_by_year = {}

daylog_data.each do |item|
  year = nil
  if item.is_a?(String)
    if md = item.match(%r{(\d\d\d\d)/\d\d/\d\d})
      year = md[1]
    end
  elsif item.is_a?(Hash)
    item.each do |k, v|
      if k != 'comment' && md = k.match(%r{(\d\d\d\d)/\d\d/\d\d})
        year = md[1]
        break
      end
    end
  end
  
  if year
    entries_by_year[year] ||= []
    entries_by_year[year] << item
  end
end

entries_by_year.each do |year, entries|
  File.write("data/daylog/#{year}.yml", entries.to_yaml({:line_width => 800}))
  puts "Generated data/daylog/#{year}.yml"
end
