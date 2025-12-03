#!/usr/bin/env ruby

Dir.glob('source/diary/**/*.md.erb').each do |file|
  content = File.read(file)
  # next unless content.match?(/^title: 東品川ごはん/)

  if content =~ /\A---\n(.*?)\n---/m
    md = $1.match(/^tags: (.*)/i)
    # puts md
    if md
      tags = md[1].split(/,/)
      tags.filter { |t| t.strip! }
      new_tags = []
      tags.each do |tag|
        if tag.match?(/(\w\w*) food/i)
          new_tags.push(tag.sub(/ food/i, ''))
        elsif tag.match?(/yokohama iekei/i)
          new_tags.push('iekei')
        elsif tag.match?(/cataract .*/i)
          new_tags.push('cataract')
        elsif tag.match?(/animals/i)
          new_tags.push('animal')
        elsif tag.match?(/documents/i)
          new_tags.push('document')
        elsif tag.match?(/business trip/i)
          new_tags.push('business')
        elsif tag.match?(/disneyland/i)
          new_tags.push('disney')
        else
          new_tags.push(tag)
        end
      end
      if tags != new_tags
        puts "#{tags.join(', ')} -> #{new_tags.join(', ')}"
        update_content = content.sub(/^tags: .*$/, "tags: #{new_tags.join(', ')}")
        File.write(file, update_content)
      end
    end
  end
end
