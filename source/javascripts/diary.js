function shouldLinkifyAddresses() {
  return window.matchMedia('(hover: hover) and (pointer: fine)').matches;
}

function decorateAddresses() {
  if (!shouldLinkifyAddresses()) return;

  var addressElements = document.querySelectorAll('pre.address');
  addressElements.forEach(function (element) {
    var lines = element.textContent.split('\n');
    if (lines.length < 2 || lines[1].trim() === '') {
      return;
    }

    var fragment = document.createDocumentFragment();
    var firstLineLink = element.querySelector('a');
    if (firstLineLink) {
      var firstLineText = firstLineLink.parentNode.firstChild;
      if (firstLineText && firstLineText.nodeType === Node.TEXT_NODE && firstLineText.textContent !== '') {
        fragment.appendChild(document.createTextNode(firstLineText.textContent));
      }
      fragment.appendChild(firstLineLink.cloneNode(true));
    } else {
      fragment.appendChild(document.createTextNode(lines[0]));
    }
    fragment.appendChild(document.createTextNode('\n'));

    var addressLink = document.createElement('a');
    addressLink.href = 'https://maps.google.co.jp/?q=' + encodeURIComponent(lines[1]);
    addressLink.textContent = lines[1];
    fragment.appendChild(addressLink);

    if (lines.length > 2) {
      fragment.appendChild(document.createTextNode('\n' + lines.slice(2).join('\n')));
    }

    element.replaceChildren(fragment);
  });
}

function decorateImageParagraphs() {
  var paragraphs = document.querySelectorAll('main p');

  paragraphs.forEach(function (paragraph) {
    var children = Array.from(paragraph.children);
    if (children.length === 0) return;

    var images = children.map(function (child) {
      if (child.tagName === 'IMG') return child;
      if (child.tagName !== 'A') return null;
      return child.querySelector('img');
    }).filter(function (img) {
      return img !== null;
    });

    if (images.some(function (image) { return image.classList.contains('no-image-grid'); })) return;

    var onlyImages = children.every(function (child) {
      if (child.tagName === 'IMG') return true;
      if (child.tagName !== 'A') return false;

      var img = child.querySelector('img');
      return img !== null && child.textContent.trim() === '';
    });

    if (!onlyImages) return;

    paragraph.classList.add('image-grid');

  });
}

document.addEventListener('DOMContentLoaded', decorateAddresses);
document.addEventListener('DOMContentLoaded', decorateImageParagraphs);
