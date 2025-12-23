#!/usr/bin/env ruby

require 'set'

REDUNDANCY_RULES = {
  'businesstrip' => %w[business work travel],
  'higashi shinagawa' => ['shinagawa'],
  'minatomirai' => ['yokohama'],
  'trail' => ['nature'],
  'park' => %w[nature outdoor playground play],
  'camp' => ['outdoor'],
  'gyoza' => ['food'],
  'uk' => ['photo']
}.freeze
MEAL_TAGS = %w[breakfast lunch dinner party].freeze

def rename_legacy_tags(tags)
  tags.map do |tag|
    case tag
    when /^documents$/i then 'document'
    when /^ren$/i then 'son'
    when /^riri$/i then 'daughter'
    else tag
    end
  end
end

def add_contextual_tags(tags, content)
  new_tags = tags.dup
  new_tags.push('lunch') if content.match?(/^title: 目黒ごはん/) && !new_tags.include?('dinner')
  new_tags.push('lunch') if content.match?(/^title: 東品川ごはん/) && !new_tags.include?('dinner')
  new_tags.push('businesstrip') if content.match?(/^title: .*出張/)
  new_tags
end

def remove_redundant_tags(tags)
  tags_set = tags.to_set

  REDUNDANCY_RULES.each do |trigger, to_delete|
    to_delete.each { |tag| tags_set.delete(tag) } if tags_set.include?(trigger)
  end

  tags_set.delete('restaurant') if (tags_set & MEAL_TAGS).any?
  tags_set.delete('theme park')

  tags_set.to_a
end

def transform_tags(original_tags, content)
  tags = rename_legacy_tags(original_tags)
  tags = add_contextual_tags(tags, content)
  tags = remove_redundant_tags(tags)

  tags.map(&:downcase).map(&:strip).reject(&:empty?).sort.uniq
end

def extract_original_tags(content)
  front_matter_match = content.match(/\A---\n(.*?)\n---/m)
  return nil unless front_matter_match

  front_matter = front_matter_match[1]
  tags_match = front_matter.match(/^tags:\s*(.*)/i)
  return nil unless tags_match

  tags_match[1].split(',').map(&:strip)
end

def process_file(file)
  content = File.read(file)
  original_tags = extract_original_tags(content)
  return if original_tags.nil?

  new_tags = transform_tags(original_tags.clone, content)

  return if original_tags.sort == new_tags.sort

  new_tags_str = new_tags.join(', ')
  puts "#{file}: #{original_tags.join(', ')} -> #{new_tags_str}"
  updated_content = content.sub(/^tags:.*$/i, "tags: #{new_tags_str}")
  File.write(file, updated_content)
end

Dir.glob('source/diary/**/*.md.erb').each do |file|
  process_file(file)
end
