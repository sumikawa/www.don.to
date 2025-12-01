// Simple inline editor for local development
document.addEventListener('DOMContentLoaded', () => {
  const sourcePath = document.body.dataset.sourcePath;
  const mainContent = document.querySelector('main[data-pagefind-body]');
  let isEditing = false;

  // Check if the page is editable
  if (!mainContent || !sourcePath || !sourcePath.startsWith('/diary/') || !sourcePath.endsWith('.md.erb')) {
    return;
  }

  mainContent.style.cursor = 'pointer';
  mainContent.title = 'Click to edit';

  const showEditor = async () => {
    if (isEditing) return;
    isEditing = true;
    mainContent.style.cursor = 'default';
    mainContent.title = '';

    const originalHTML = mainContent.innerHTML;

    // Fetch original markdown content
    let markdownContent = '';
    try {
      const apiPath = sourcePath.substring(1); // Remove leading '/'
      const response = await fetch(`${window.location.origin}/api/${apiPath}`);
      if (!response.ok) throw new Error('Failed to fetch content');
      const data = await response.json();
      markdownContent = data.content;
    } catch (error) {
      console.error('Error fetching content:', error);
      alert('Could not load content to edit.');
      isEditing = false;
      mainContent.style.cursor = 'pointer';
      mainContent.title = 'Click to edit';
      return;
    }

    // Create textarea and buttons
    const editorWrapper = document.createElement('div');
    editorWrapper.style.height = `${mainContent.offsetHeight}px`;

    const textarea = document.createElement('textarea');
    textarea.value = markdownContent;
    textarea.style.width = '100%';
    textarea.style.height = '100%';
    textarea.style.minHeight = '300px';
    textarea.style.boxSizing = 'border-box';

    const buttonContainer = document.createElement('div');
    buttonContainer.style.marginTop = '10px';
    buttonContainer.style.textAlign = 'right';

    const saveButton = document.createElement('button');
    saveButton.textContent = 'Save';
    saveButton.style.marginLeft = '10px';

    const cancelButton = document.createElement('button');
    cancelButton.textContent = 'Cancel';

    buttonContainer.appendChild(cancelButton);
    buttonContainer.appendChild(saveButton);

    editorWrapper.appendChild(textarea);
    editorWrapper.appendChild(buttonContainer);

    // Replace content with editor
    mainContent.innerHTML = '';
    mainContent.appendChild(editorWrapper);
    textarea.focus();

    const cleanup = () => {
      mainContent.innerHTML = originalHTML;
      isEditing = false;
      mainContent.style.cursor = 'pointer';
      mainContent.title = 'Click to edit';
    };

    // --- Event Listeners for buttons ---
    cancelButton.addEventListener('click', (e) => {
      e.stopPropagation();
      cleanup();
    });

    saveButton.addEventListener('click', async (e) => {
      e.stopPropagation();
      saveButton.disabled = true;
      cancelButton.disabled = true;
      saveButton.textContent = 'Saving...';

      try {
        const apiPath = sourcePath.substring(1);
        const response = await fetch(`${window.location.origin}/api/`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ path: apiPath, content: textarea.value }),
        });

        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.error || 'Failed to save');
        }

        displayTemporaryMessage('Saved successfully!', 2000);
        window.location.reload();
      } catch (error) {
        console.error('Error saving:', error);
        displayTemporaryMessage(`Failed to save file: ${error.message}`, 3000); // Display error for 3 seconds
        saveButton.disabled = false;
        cancelButton.disabled = false;
        saveButton.textContent = 'Save';
      }
    });
  };

  mainContent.addEventListener('click', showEditor);
});

function displayTemporaryMessage(message, duration) {
  const messageDiv = document.createElement('div');
  messageDiv.textContent = message;
  Object.assign(messageDiv.style, {
    position: 'fixed',
    top: '50%',
    left: '50%',
    transform: 'translate(-50%, -50%)',
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    color: 'white',
    padding: '15px 25px',
    borderRadius: '5px',
    zIndex: '1000',
    opacity: '0',
    transition: 'opacity 0.5s ease-in-out',
    textAlign: 'center'
  });

  document.body.appendChild(messageDiv);

  // Fade in
  setTimeout(() => {
    messageDiv.style.opacity = '1';
  }, 10); // Small delay to trigger transition

  // Fade out and remove
  setTimeout(() => {
    messageDiv.style.opacity = '0';
    messageDiv.addEventListener('transitionend', () => {
      messageDiv.remove();
    });
  }, duration);
}
