if (RegExp(' AppleWebKit.*Mobile|Opera Mini|Mozilla.*Android').test(navigator.userAgent)) {
  // 何もしない
} else {
  document.addEventListener('DOMContentLoaded', function () {
    var addressElements = document.querySelectorAll('pre.address');
    addressElements.forEach(function (element) {
      var replaced = element.innerHTML.replace(/(.*\n)?([äöüÄÖÜß\w ,.-]+|.*市[^\n]*|.*町[^\n]*|.*県[^\n]*|.*区[^\n]*|.*号[^\n]*)(\n.*)?/, function(match, p1, p2, p3) {
        return p1 + '<a href="http://maps.google.co.jp/?q=' + p2 + '">' + p2 + '</a>' + p3;
      });

      var query = RegExp.$2.replace(/\s/g, ''); // スペースを削除
      element.innerHTML = replaced;
    });
  });
}
