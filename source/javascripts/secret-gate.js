function base64ToBytes(base64) {
  var binary = window.atob(base64);
  var bytes = new Uint8Array(binary.length);

  for (var i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }

  return bytes;
}

async function deriveSecretPageKey(password, salt, iterations) {
  var material = await window.crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveKey']
  );

  return window.crypto.subtle.deriveKey(
    {
      name: 'PBKDF2',
      salt: salt,
      iterations: iterations,
      hash: 'SHA-256'
    },
    material,
    {
      name: 'AES-GCM',
      length: 256
    },
    false,
    ['decrypt']
  );
}

async function decryptSecretPage(payload, password) {
  var salt = base64ToBytes(payload.salt);
  var iv = base64ToBytes(payload.iv);
  var ciphertext = base64ToBytes(payload.ciphertext);
  var key = await deriveSecretPageKey(password, salt, payload.iterations);
  var plaintext = await window.crypto.subtle.decrypt(
    {
      name: 'AES-GCM',
      iv: iv
    },
    key,
    ciphertext
  );

  return new TextDecoder().decode(plaintext);
}

function unlockSecretPage(html) {
  var container = document.getElementById('secret-page-content');
  if (!container) return;

  container.innerHTML = html;
  document.body.classList.remove('secret-locked');
}

function initializeSecretGate() {
  var body = document.body;
  if (!body || body.dataset.secretPage !== 'true') return;

  var payloadElement = document.getElementById('secret-page-payload');
  var form = document.getElementById('secret-gate-form');
  var input = document.getElementById('secret-gate-password');
  var message = document.getElementById('secret-gate-message');

  if (!payloadElement || !form || !input || !message) return;

  if (!window.crypto || !window.crypto.subtle || typeof TextEncoder === 'undefined' || typeof TextDecoder === 'undefined') {
    message.textContent = 'This browser cannot decrypt protected pages.';
    message.classList.add('secret-gate__message--visible');
    return;
  }

  var payload;
  try {
    payload = JSON.parse(payloadElement.textContent);
  } catch (_error) {
    message.textContent = 'This page payload is invalid.';
    message.classList.add('secret-gate__message--visible');
    return;
  }

  input.focus();

  form.addEventListener('submit', async function (event) {
    event.preventDefault();
    message.textContent = '';
    message.classList.remove('secret-gate__message--visible');

    try {
      var html = await decryptSecretPage(payload, input.value);
      input.value = '';
      unlockSecretPage(html);
    } catch (_error) {
      message.textContent = 'Incorrect password.';
      message.classList.add('secret-gate__message--visible');
      input.select();
    }
  });
}

document.addEventListener('DOMContentLoaded', initializeSecretGate);
