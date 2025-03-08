document.addEventListener('DOMContentLoaded', function() {
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

      // Set both blocks to the height of the taller one
      maxHeight = Math.max(mainBlockHeight, eachindexBlockHeight);
	  if (screen.width > 480) {
        mainBlock.style.height = maxHeight + 'px';
        eachindexBlock.style.height = maxHeight + 'px';
      }
    }
  }

  // Run on page load
  equalizeBlockHeights();

  // Run on window resize
  window.addEventListener('resize', function() {
    // Use debounce to avoid excessive calculations during resize
    clearTimeout(window.resizeTimer);
    window.resizeTimer = setTimeout(equalizeBlockHeights, 250);
  });
});
