if (RegExp(' AppleWebKit.*Mobile|Opera Mini|Mozilla.*Android').test(navigator.userAgent)) {
  // Do nothing
} else {
  document.addEventListener('DOMContentLoaded', function () {
    var addressElements = document.querySelectorAll('pre.address');
    addressElements.forEach(function (element) {
      var re = /(.*\n)([\u0041-\u005A\u0061-\u007A\u00C0-\u00FF\u0102\u0103\u0110\u0111\u1EA0-\u1EF9ũơäöüÄÖÜß\w ,.-]+|.*市[^\n]*|.*町[^\n]*|.*県[^\n]*|.*区[^\n]*|.*号[^\n]*)(\n.*)?/;
      var matched = element.innerHTML.match(re);
      if (matched != null && matched[2] != undefined) {
        element.innerHTML = matched[1] + '<a href="http://maps.google.co.jp/?q=' + matched[2] + '">'
          + matched[2] + '</a>' + matched[3];
      }
    });
  });
}

docsearch({
  appId: '0B5BZHRPI9',
  apiKey: 'cad927f6eb5fcbe955b896b1df679d49',
  indexName: 'donto',
  inputSelector: '#search',
  debug: false
});

document.addEventListener('DOMContentLoaded', function () {
  // Function to equalize heights of centerblock and leftblock
  function equalizeBlockHeights() {
    mainBlock = document.querySelector('.mainblock');
    eachindexBlock = document.querySelector('.eachindexblock');

    if (mainBlock && eachindexBlock) {
      // Reset heights to auto to get their natural heights
      mainBlock.style.height = 'auto';
      eachindexBlock.style.height = 'auto';

      // Get the computed heights
      mainBlockHeight = mainBlock.offsetHeight;
      eachindexBlockHeight = eachindexBlock.offsetHeight;
      screenHeight = window.innerHeight - 20;

      // Set both blocks to the height of the taller one
      maxHeight = Math.max(mainBlockHeight, eachindexBlockHeight, screenHeight);
      if (screen.width > 480) {
        mainBlock.style.height = maxHeight + 'px';
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
});
