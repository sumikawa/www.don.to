#!/usr/bin/env ruby
require 'yaml'
require 'pp'

yaml = YAML.load_file('daylog.yml')

yaml.sort_by! do |i|
  day = ''
  if i.is_a? Hash
    i.each_key do |k|
      next if k == 'comment'

      day = k
    end
  else
    day = i
  end
  day
end

YAML.dump(yaml.reverse, File.open('daylog2.yml', 'w'), { line_width: 1000, header: false })
