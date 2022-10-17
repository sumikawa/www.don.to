# -*- coding: utf-8 -*-
if RegExp(' AppleWebKit.*Mobile|Opera Mini|Mozilla.*Android').test(navigator.userAgent)
# do nothing
#else if RegExp(' AppleWebKit.*Mobile|Mozilla.*Android').test(navigator.userAgent)
#  $ ->
#    $('a.video').each ->
#      href = $(this).attr('href')
#      src = $(this).children().attr('src')
#      poster = src.replace(/video\/\d+/, 'video/96')
#      $(this).replaceWith "<video poster=\"#{poster}\" height=\"96\"><source src=\"#{href}\" type=\"video/mp4\"></video>"
else
  $ ->
    $('pre.address').each ->
      replaced = $(this).html().replace(/(.*\n)?([äöüÄÖÜß\w ,.-]+|.*市[^\n]*|.*町[^\n]*|.*県[^\n]*|.*区[^\n]*|.*号[^\n]*)(\n.*)?/, '$1<a href="http://maps.google.co.jp/?q=$2">$2</a>$3')
      query = RegExp.$2.replace(RegExp(' ', 'g'), '')
      $(this).html replaced
