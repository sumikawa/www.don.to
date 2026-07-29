function bytesToHex(bytes) {
  return Array.from(bytes, function (byte) {
    return byte.toString(16).padStart(2, '0');
  }).join('');
}

async function sha256Hex(text) {
  var buffer = await window.crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return bytesToHex(new Uint8Array(buffer));
}

function unlockSecretPage(digest) {
  document.body.classList.remove('secret-locked');

  try {
    window.sessionStorage.setItem('secret-gate:' + digest, 'ok');
  } catch (_error) {
    // Ignore storage failures and keep the page unlocked for this load.
  }
}

function initializeSecretGate() {
  var body = document.body;
  if (!body || body.dataset.secretPage !== 'true') return;

  var digest = (body.dataset.secretPasswordSha256 || '').trim().toLowerCase();
  var form = document.getElementById('secret-gate-form');
  var input = document.getElementById('secret-gate-password');
  var message = document.getElementById('secret-gate-message');

  if (!form || !input || !message) return;

  if (!window.crypto || !window.crypto.subtle || typeof TextEncoder === 'undefined') {
    message.textContent = 'This browser cannot verify the password on the client side.';
    message.classList.add('secret-gate__message--visible');
    return;
  }

  if (!/^[0-9a-f]{64}$/.test(digest)) {
    message.textContent = 'This page is missing its password hash configuration.';
    message.classList.add('secret-gate__message--visible');
    return;
  }

  try {
    if (window.sessionStorage.getItem('secret-gate:' + digest) === 'ok') {
      unlockSecretPage(digest);
      return;
    }
  } catch (_error) {
    // Ignore storage failures and continue with normal prompt flow.
  }

  input.focus();

  form.addEventListener('submit', async function (event) {
    event.preventDefault();
    message.textContent = '';
    message.classList.remove('secret-gate__message--visible');

    var password = input.value;
    var candidateDigest = await sha256Hex(password);

    if (candidateDigest === digest) {
      unlockSecretPage(digest);
      input.value = '';
      return;
    }

    message.textContent = 'Incorrect password.';
    message.classList.add('secret-gate__message--visible');
    input.select();
  });
}

document.addEventListener('DOMContentLoaded', initializeSecretGate);
