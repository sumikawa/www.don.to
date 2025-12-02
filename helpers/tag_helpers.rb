# helpers/tag_helpers.rb
require 'yaml'

module TagHelpers
  def tags_list
    all_tags = {}

    # Assuming Middleman's root directory structure
    # Adjust path if necessary
    diary_files = Dir.glob("source/diary/2025/**/*.html.md.erb")

    diary_files.each do |file_path|
      content = File.read(file_path)

      # Extract YAML front matter
      if content =~ /\A(---\s*\n.*?\n---\s*\n)/m
        front_matter_str = $1
        begin
          data = YAML.load(front_matter_str)
          if data && data['tags']
            # Split tags string by comma and strip whitespace
            tags = data['tags'].split(',').map(&:strip)
            tags.each do |tag|
              all_tags[tag] ||= []
              all_tags[tag].push(file_path)
            end
          end
        rescue Psych::SyntaxError => e
          puts "Error parsing YAML in #{file_path}: #{e.message}"
        end
      end
    end

    all_tags
  end
end
