# frozen_string_literal: true

require 'base64'
require 'json'
require 'openssl'
require 'securerandom'

module SecretPageHelpers
  SECRET_PAGE_KDF_ITERATIONS = 210_000
  SECRET_PAGE_KEY_BYTES = 32
  SECRET_PAGE_SALT_BYTES = 16
  SECRET_PAGE_IV_BYTES = 12
  SECRET_PAGE_AUTH_TAG_BYTES = 16

  def encrypted_secret_page_payload_json(plaintext)
    JSON.generate(encrypted_secret_page_payload(plaintext))
  end

  def encrypted_secret_page_payload(plaintext)
    salt = SecureRandom.random_bytes(SECRET_PAGE_SALT_BYTES)
    iv = SecureRandom.random_bytes(SECRET_PAGE_IV_BYTES)
    cipher = build_secret_page_cipher(:encrypt, derive_secret_page_key(secret_page_password!, salt), iv)
    encrypted = encrypt_secret_page_plaintext(cipher, plaintext)

    {
      v: 1,
      kdf: 'PBKDF2-HMAC-SHA256',
      iterations: SECRET_PAGE_KDF_ITERATIONS,
      cipher: 'AES-256-GCM',
      salt: Base64.strict_encode64(salt),
      iv: Base64.strict_encode64(iv),
      ciphertext: Base64.strict_encode64(encrypted)
    }
  end

  def secret_page_password!
    password = ENV['SECRET_PAGE_PASSWORD'].to_s
    return password unless password.empty?

    raise 'SECRET_PAGE_PASSWORD is required to render pages tagged with secret'
  end

  def decrypt_secret_page_payload(payload, password)
    salt, initialization_vector, ciphertext, auth_tag = decode_secret_page_payload(payload)
    cipher = build_secret_page_cipher(
      :decrypt,
      derive_secret_page_key(password, salt, payload.fetch('iterations')),
      initialization_vector
    )
    cipher.auth_tag = auth_tag
    cipher.update(ciphertext) + cipher.final
  end

  private

  def derive_secret_page_key(password, salt, iterations = SECRET_PAGE_KDF_ITERATIONS)
    OpenSSL::PKCS5.pbkdf2_hmac(password, salt, iterations, SECRET_PAGE_KEY_BYTES, 'sha256')
  end

  def decode_secret_page_payload(payload)
    encrypted = Base64.strict_decode64(payload.fetch('ciphertext'))

    [
      Base64.strict_decode64(payload.fetch('salt')),
      Base64.strict_decode64(payload.fetch('iv')),
      encrypted[0...-SECRET_PAGE_AUTH_TAG_BYTES],
      encrypted[-SECRET_PAGE_AUTH_TAG_BYTES..]
    ]
  end

  def build_secret_page_cipher(mode, key, initialization_vector)
    OpenSSL::Cipher.new('aes-256-gcm').tap do |cipher|
      cipher.public_send(mode)
      cipher.key = key
      cipher.iv = initialization_vector
    end
  end

  def encrypt_secret_page_plaintext(cipher, plaintext)
    ciphertext = cipher.update(plaintext.to_s) + cipher.final
    ciphertext + cipher.auth_tag(SECRET_PAGE_AUTH_TAG_BYTES)
  end
end
