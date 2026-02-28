#!/usr/bin/env ruby
require 'yaml'

def tags_for_file(file_path)
  content = File.read(file_path)
  return [] unless content =~ /\A(---\s*
.*?
---\s*
)/m

  front_matter = YAML.safe_load(::Regexp.last_match(1))
  return [] unless front_matter && front_matter['tags']

  front_matter['tags'].split(',').map(&:strip).map(&:downcase)
rescue Psych::SyntaxError => e
  puts "Error parsing YAML in #{file_path}: #{e.message}"
  []
end

untagged_files = []

tags_list = Dir.glob('source/diary/[012]*/**/*.html.md.erb').each_with_object({}) do |file_path, all_tags|
  tags = tags_for_file(file_path)
  if tags.empty?
    untagged_files << file_path
  else
    tags.each do |tag|
      all_tags[tag] ||= []
      all_tags[tag] << file_path
    end
  end
end

unless untagged_files.empty?
  puts "Untagged files found (#{untagged_files.size}):"
  untagged_files.each { |f| puts "  #{f}" }
  puts "-" * 20
end

# Sort by tag name
sorted_tags_list = tags_list.sort.to_h

File.write('data/tags.yml', sorted_tags_list.to_yaml)
puts "Generated data/tags.yml with #{sorted_tags_list.keys.size} tags (sorted)."
