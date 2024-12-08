(function() {
  if (RegExp(' AppleWebKit.*Mobile|Opera Mini|Mozilla.*Android').test(navigator.userAgent)) {

  } else {
    $(function() {
      return $('pre.address').each(function() {
        var query, replaced;
        replaced = $(this).html().replace(/(.*\n)?([äöüÄÖÜß\w ,.-]+|.*市[^\n]*|.*町[^\n]*|.*県[^\n]*|.*区[^\n]*|.*号[^\n]*)(\n.*)?/, '$1<a href="http://maps.google.co.jp/?q=$2">$2</a>$3');
        query = RegExp.$2.replace(RegExp(' ', 'g'), '');
        return $(this).html(replaced);
      });
    });
  }

}).call(this);
