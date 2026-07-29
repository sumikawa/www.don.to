#!/usr/bin/env ruby

limit = 30
result = []
prompt = "以下のファイルのヘッダに 'tags: TAG1, TAG2, TAG3'の形式でタグ情報を追加したい。タグはそれぞれのファイルの本文を解析して適切なタグを抽出してください。既にタグが追加されている2025年もしくは2026年のerbファイルを参考にすること。ファイル名の'-'移行が同じファイルは類似性が高い。既存タグのリストは data/tags.yml にあるのでこれも参考にすること。タグの数は最大3つまで。タグは英文字であること。\n"

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

result = result.join("\n")
puts "#{prompt} #{result}"
