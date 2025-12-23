#!/usr/bin/env ruby

limit = 30
result = []
prompt = "以下のファイルのヘッダに 'tags: TAG1, TAG2, TAG3'の形式でタグ情報を追加したい。タグはそれぞれのファイルの本文を解析して適切なタグを抽出すること。タグの数は最大3つまで。タグは英文字であること"

ARGV.each do |file|
  next unless File.exist?(file)
  break if limit < 1

  content = File.read(file)
  if (content =~ /\A---\n(.*?)\n---/m) && !Regexp.last_match(1).match?(/^tags:/i)
    result << file
    limit -= 1
  end
end

exit(1) if limit == 30 # no file without tags

puts "#{prompt} #{result.join(' ')}"
