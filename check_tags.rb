#!/usr/bin/env ruby

limit = 30

print "以下のファイルのヘッダに 'tags: TAG1, TAG2, TAG3'の形式でタグ情報を追加したい。タグはそれぞれのファイルの本文を解析して適切なタグを抽出すること。タグの数は最大3つまで。タグは英文字であること"

ARGV.each do |file|
  next unless File.exist?(file)
  exit if limit < 1

  content = File.read(file)
  if content =~ /\A---\n(.*?)\n---/m
    unless $1.match?(/^tags:/i)
      print file
      limit = limit - 1
    end
  end
end
