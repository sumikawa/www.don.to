#!/usr/bin/env ruby
require 'yaml'
require 'pp'

yaml = YAML.load_file('daylog.yml')

yaml.sort_by! { |i|
  day = ''
  if i.is_a? Hash
    i.each_key { |k|
      next if k == 'comment'

      day = k
    }
  else
    day = i
  end
  day
}

YAML.dump(yaml.reverse, File.open('daylog2.yml', 'w'), { line_width: 1000, header: false })
