if (RegExp(' AppleWebKit.*Mobile|Opera Mini|Mozilla.*Android').test(navigator.userAgent)) {
  // Do nothing
} else {
  document.addEventListener('DOMContentLoaded', function () {
    var addressElements = document.querySelectorAll('pre.address');
    addressElements.forEach(function (element) {
      var re = /(.*\n)([\u0041-\u005A\u0061-\u007A\u00C0-\u00FF\u0102\u0103\u0110\u0111\u1EA0-\u1EF9ĩưũơäöüÄÖÜßÇçĞğÖöŞşÜüİı\w :,./+-]+|.*市[^\n]*|.*町[^\n]*|.*県[^\n]*|.*区[^\n]*|.*号[^\n]*)(\n.*)?/;
      var matched = element.innerHTML.match(re);
      if (matched != null && matched[2] != undefined) {
        element.innerHTML = matched[1] + '<a href="http://maps.google.co.jp/?q=' + matched[2] + '">'
          + matched[2] + '</a>' + matched[3];
      }
    });
  });
}

function decorateImageParagraphs() {
  var paragraphs = document.querySelectorAll('main[data-pagefind-body] p');

  paragraphs.forEach(function (paragraph) {
    var children = Array.from(paragraph.children);
    if (children.length === 0) return;

    var onlyImages = children.every(function (child) {
      if (child.tagName === 'IMG') return true;
      if (child.tagName !== 'A') return false;

      var img = child.querySelector('img');
      return img !== null && child.textContent.trim() === '';
    });

    if (onlyImages) {
      paragraph.classList.add('image-grid');
    }
  });
}

document.addEventListener('DOMContentLoaded', decorateImageParagraphs);
