if (RegExp(' AppleWebKit.*Mobile|Opera Mini|Mozilla.*Android').test(navigator.userAgent)) {
  // Do nothing
} else {
  document.addEventListener('DOMContentLoaded', function () {
    var addressElements = document.querySelectorAll('pre.address');
    addressElements.forEach(function (element) {
      var re = /(.*\n)([\u0041-\u005A\u0061-\u007A\u00C0-\u00FF\u0102\u0103\u0110\u0111\u1EA0-\u1EF9ĩưũơäöüÄÖÜß\w ,./+-]+|.*市[^\n]*|.*町[^\n]*|.*県[^\n]*|.*区[^\n]*|.*号[^\n]*)(\n.*)?/;
      var matched = element.innerHTML.match(re);
      if (matched != null && matched[2] != undefined) {
        element.innerHTML = matched[1] + '<a href="http://maps.google.co.jp/?q=' + matched[2] + '">'
          + matched[2] + '</a>' + matched[3];
      }
    });
  });
}

function resizeBlock() {
  // Function to equalize heights of centerblock and leftblock
  function equalizeBlockHeights() {
    titleBlock = document.querySelector('.titleblock');
    mainBlock = document.querySelector('.mainblock');
    eachindexBlock = document.querySelector('.eachindexblock');

    if (mainBlock && eachindexBlock) {
      // Reset heights to auto to get their natural heights
      titleBlock.style.height = 'auto';
      mainBlock.style.height = 'auto';
      eachindexBlock.style.height = 'auto';

      // Get the computed heights
	  margin = 5;
      titleBlockHeight = titleBlock.offsetHeight;
      mainBlockHeight = mainBlock.offsetHeight;
      eachindexBlockHeight = eachindexBlock.offsetHeight;
      screenHeight = window.innerHeight - 20;

      // Set both blocks to the height of the taller one
      maxHeight = Math.max(mainBlockHeight + margin + titleBlock.offsetHeight, eachindexBlockHeight, screenHeight);
      if (screen.width > 480) {
        mainBlock.style.height = (maxHeight - titleBlock.offsetHeight - margin) + 'px';
        eachindexBlock.style.height = maxHeight + 'px';
      }
    }
  }

  // Run on page load
  equalizeBlockHeights();

  // Run on window resize
  window.addEventListener('resize', function () {
    // Use debounce to avoid excessive calculations during resize
    clearTimeout(window.resizeTimer);
    window.resizeTimer = setTimeout(equalizeBlockHeights, 250);
  });
}

document.addEventListener('DOMContentLoaded', resizeBlock);
window.addEventListener('load', resizeBlock);
