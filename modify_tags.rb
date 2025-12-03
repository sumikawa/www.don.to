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
        elsif tag.match?(/^yokohama iekei$/i)
          new_tags.push('iekei')
        elsif tag.match?(/^cataract .*$/i)
          new_tags.push('cataract')
        elsif tag.match?(/^animals$/i)
          new_tags.push('animal')
        elsif tag.match?(/^documents$/i)
          new_tags.push('document')
        elsif tag.match?(/^walking$/i)
          new_tags.push('walk')
        elsif tag.match?(/^usa$/i)
          new_tags.push('us')
        elsif tag.match?(/^business[- ]trip$/i)
          new_tags.push('business')
        elsif tag.match?(/^disneyland$/i)
          new_tags.push('disney')
        elsif tag.match?(/^newyear$/i)
          new_tags.push('new year')
        elsif tag.match?(/^babies$/i)
          new_tags.push('baby')
        elsif tag.match?(/^siblings$/i)
          new_tags.push('sibling')
        elsif tag.match?(/^bicycle$/i)
          new_tags.push('bike')
        elsif tag.match?(/^bento$/i)
          new_tags.push('lunchbox')
        elsif tag.match?(/^morning activity$/i)
          new_tags.push('morning')
        elsif tag.match?(/^kindergarten$/i)
          new_tags.push('daycare')
        elsif tag.match?(/^theme-?park$/i)
          new_tags.push('theme park')
        elsif tag.match?(/^sports-?day$/i)
          new_tags.push('sports day')
        elsif tag.match?(/^newborn$/i)
          new_tags.push('birth')
        elsif tag.match?(/^potato digging$/i)
          new_tags.push('potato')
        elsif tag.match?(/^wfh$/i)
          new_tags.push('telework')
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
