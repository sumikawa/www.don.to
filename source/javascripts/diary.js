if (RegExp(' AppleWebKit.*Mobile|Opera Mini|Mozilla.*Android').test(navigator.userAgent)) {
  // Do nothing
} else {
  document.addEventListener('DOMContentLoaded', function () {
    var addressElements = document.querySelectorAll('pre.address');
    addressElements.forEach(function (element) {
      var re = /(.*\n)([äöüÄÖÜß\w ,.-]+|.*市[^\n]*|.*町[^\n]*|.*県[^\n]*|.*区[^\n]*|.*号[^\n]*)(\n.*)?/;
      var matched = element.innerHTML.match(re);
      if (matched != null && matched[2] != undefined) {
        element.innerHTML = matched[1] + '<a href="http://maps.google.co.jp/?q=' + matched[2] + '">'
          + matched[2] + '</a>' + matched[3];
      }
    });
  });
}
