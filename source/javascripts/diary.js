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

window.addEventListener('DOMContentLoaded', (event) => {
  new PagefindUI({ element: "#search", showImages: false, excerptLength: 100, sort: { date: "desc" }});
});

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

// Simple editor for local development
document.addEventListener('DOMContentLoaded', () => {
  // Elements
  const editButton = document.getElementById('edit-button');
  const modal = document.getElementById('edit-modal');
  const saveButton = document.getElementById('save-button');
  const cancelButton = document.getElementById('cancel-button');
  const textarea = document.getElementById('edit-textarea');
  const sourcePath = document.body.dataset.sourcePath;

  // Check if the necessary elements exist
  if (!editButton || !modal || !sourcePath) {
    return;
  }
  
  // The edit button should only be visible for editable pages.
  // We can check if the source path points to a file in the diary directory.
  if (!sourcePath.startsWith('/diary/') || !sourcePath.endsWith('.md.erb')) {
      editButton.style.display = 'none';
      return;
  }
  
  // Show Modal
  editButton.addEventListener('click', async () => {
    try {
      // Use the source path from the data attribute. The API expects the path relative to the 'source' dir.
      const apiPath = sourcePath.substring(1); // Remove leading '/'
      const response = await fetch(`http://localhost:9292/api/${apiPath}`);
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(`Error fetching file: ${errorData.error || response.statusText}`);
      }

      const data = await response.json();
      textarea.value = data.content;
      modal.style.display = 'flex';
    } catch (error) {
      console.error('Error:', error);
      alert('Failed to load file content.');
    }
  });

  // Hide Modal
  cancelButton.addEventListener('click', () => {
    modal.style.display = 'none';
  });

  // Save Content
  saveButton.addEventListener('click', async () => {
    const apiPath = sourcePath.substring(1); // Remove leading '/'
    try {
      const response = await fetch('http://localhost:9292/api/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          path: apiPath,
          content: textarea.value,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(`Error saving file: ${errorData.error || response.statusText}`);
      }

      const result = await response.json();
      if (result.success) {
        alert('Saved successfully!');
        modal.style.display = 'none';
        window.location.reload();
      } else {
        throw new Error(result.error || 'Unknown error');
      }
    } catch (error) {
      console.error('Error:', error);
      alert(`Failed to save file: ${error.message}`);
    }
  });
});
