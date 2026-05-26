// Simple inline editor for local development
document.addEventListener('DOMContentLoaded', () => {
  const sourcePath = document.body.dataset.sourcePath;
  const mainContent = document.querySelector('main');
  const mainBlock = document.querySelector('.mainblock');

  let isEditing = false;

  if (
    !mainBlock ||
    !mainContent ||
    !sourcePath ||
    !sourcePath.startsWith('/diary/')
  ) {
    return;
  }

  const editButton = document.createElement('button');
  editButton.textContent = 'Edit';
  editButton.classList.add('edit-button');

  const githubButton = document.createElement('button');
  githubButton.textContent = 'GitHub';
  githubButton.classList.add('github-button');

  mainBlock.appendChild(editButton);
  mainBlock.appendChild(githubButton);

  githubButton.addEventListener('click', () => {
    const githubUrl = `https://github.com/sumikawa/www.don.to/edit/main/source${sourcePath}`;
    window.open(githubUrl, '_blank');
  });

  const showEditor = async () => {
    if (isEditing) return;
    isEditing = true;
    editButton.hidden = true;
    githubButton.hidden = true;

    const originalHTML = mainContent.innerHTML;

    // Fetch original markdown content
    let markdownContent = '';
    const getBaseUrl = () => {
      if (window.location.hostname === 'localhost') {
        return `${window.location.protocol}//${window.location.hostname}:9292`;
      }
      return window.location.origin;
    };
    const baseUrl = getBaseUrl();
    try {
      const apiPath = sourcePath.substring(1); // Remove leading '/'
      const response = await fetch(`${baseUrl}/api/${apiPath}`);
      if (!response.ok) throw new Error('Failed to fetch content');
      const data = await response.json();
      markdownContent = data.content;
    } catch (error) {
      console.error('Error fetching content:', error);
      isEditing = false;
      editButton.hidden = false;
      githubButton.hidden = false;
      return;
    }

    // Create textarea and buttons
    const editorWrapper = document.createElement('div');
    editorWrapper.classList.add('editor-wrapper');

    const textarea = document.createElement('textarea');
    textarea.classList.add('editor-textarea');
    textarea.value = markdownContent;

    // Auto-resize textarea height
    const adjustTextareaHeight = () => {
      textarea.style.height = 'auto';
      const newHeight = Math.min(textarea.scrollHeight, window.innerHeight * 0.8);
      textarea.style.height = `${newHeight}px`;
    };

    textarea.addEventListener('input', adjustTextareaHeight);
    // Adjust height initially in case content is pre-filled
    adjustTextareaHeight();


    const buttonContainer = document.createElement('div');
    buttonContainer.classList.add('editor-actions');

    const saveButton = document.createElement('button');
    saveButton.textContent = 'Save';
    saveButton.classList.add('editor-save-button');

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
    textarea.setSelectionRange(0, 0); // Move cursor to the beginning


    const cleanup = () => {
      mainContent.innerHTML = originalHTML;
      isEditing = false;
      editButton.hidden = false;
      githubButton.hidden = false;
      initPhotoSwipeFromDOM('.mainblock');
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
        const response = await fetch(`${baseUrl}/api/`, {
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

  editButton.addEventListener('click', showEditor);
});

function displayTemporaryMessage(message, duration) {
  const messageDiv = document.createElement('div');
  messageDiv.classList.add('editor-toast');
  messageDiv.textContent = message;

  document.body.appendChild(messageDiv);

  // Fade in
  setTimeout(() => {
    messageDiv.classList.add('is-visible');
  }, 10);

  // Fade out and remove
  setTimeout(() => {
    messageDiv.classList.remove('is-visible');
    messageDiv.addEventListener('transitionend', () => {
      messageDiv.remove();
    });
  }, duration);
}
