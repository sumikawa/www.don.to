#!/usr/bin/env ruby

Dir.glob('source/diary/**/*.md.erb').each do |file|
  content = File.read(file)

  next unless content =~ /\A---\n(.*?)\n---/m

  md = Regexp.last_match(1).match(/^tags:(.*)/i)
  # puts md
  next unless md

  tags = md[1].split(',')
  tags.filter(&:strip!)
  new_tags = []
  tags.each do |tag|
    case tag
    when /^documents$/i
      new_tags.push('document')
    when /^ren$/i
      new_tags.push('son')
    when /^riri$/i
      new_tags.push('daughter')
    else
      new_tags.push(tag)
    end
  end

  new_tags.push('lunch') if content.match?(/^title: 目黒ごはん/) & !new_tags.include?('dinner')
  new_tags.push('lunch') if content.match?(/^title: 東品川ごはん/) & !new_tags.include?('dinner')

  if content.match?(/^title: .*出張/)
    new_tags.push('businesstrip')
    new_tags.delete('business') if new_tags.include?('business')
    new_tags.delete('travel') if new_tags.include?('travel')
  end

  new_tags = new_tags.map(&:downcase).map(&:strip).delete_if { |t| t == '' }

  new_tags.delete('theme park')

  # puts new_tags

  new_tags.delete('business') if new_tags.include?('businesstrip') & new_tags.include?('business')
  new_tags.delete('work') if new_tags.include?('businesstrip') & new_tags.include?('work')
  new_tags.delete('photo') if new_tags.include?('uk') & new_tags.include?('photo')
  new_tags.delete('shinagawa') if new_tags.include?('higashi shinagawa') & new_tags.include?('shinagawa')
  new_tags.delete('nature') if new_tags.include?('trail') & new_tags.include?('nature')
  new_tags.delete('outdoor') if new_tags.include?('park') & new_tags.include?('outdoor')
  new_tags.delete('nature') if new_tags.include?('park') & new_tags.include?('nature')
  new_tags.delete('outdoor') if new_tags.include?('camp') & new_tags.include?('outdoor')
  new_tags.delete('playground') if new_tags.include?('park') & new_tags.include?('playground')
  new_tags.delete('food') if new_tags.include?('food') & new_tags.include?('gyoza')
  new_tags.delete('restaurant') if new_tags.include?('restaurant') & new_tags.include?('breakfast')
  new_tags.delete('restaurant') if new_tags.include?('restaurant') & new_tags.include?('lunch')
  new_tags.delete('restaurant') if new_tags.include?('restaurant') & new_tags.include?('dinner')
  new_tags.delete('restaurant') if new_tags.include?('restaurant') & new_tags.include?('party')
  new_tags.delete('play') if new_tags.include?('park') & new_tags.include?('play')
  new_tags.delete('yokohama') if new_tags.include?('minatomirai') & new_tags.include?('yokohama')

  new_tags = new_tags.sort.uniq
  update_content = content.sub(/^tags:.*$/, "tags: #{new_tags.join(', ')}")
  if content != update_content
    puts "#{tags.join(', ')} -> #{new_tags.join(', ')}"
    File.write(file, update_content)
  end
end
