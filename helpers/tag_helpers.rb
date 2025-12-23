# helpers/tag_helpers.rb
require 'yaml'

module TagHelpers
  def tags_list
    @tags_list ||= Dir.glob('source/diary/[012]*/**/*.html.md.erb').each_with_object({}) do |file_path, all_tags|
      process_file_tags(file_path, all_tags)
    end
  end

  private

  def process_file_tags(file_path, all_tags)
    tags_for_file(file_path).each do |tag|
      all_tags[tag] ||= []
      all_tags[tag] << file_path
    end
  rescue Psych::SyntaxError => e
    puts "Error parsing YAML in #{file_path}: #{e.message}"
  end

  def tags_for_file(file_path)
    content = File.read(file_path)
    return [] unless content =~ /\A(---\s*\n.*?\n---\s*\n)/m

    front_matter = YAML.safe_load(::Regexp.last_match(1))
    return [] unless front_matter && front_matter['tags']

    front_matter['tags'].split(',').map(&:strip).map(&:downcase)
  end
end
