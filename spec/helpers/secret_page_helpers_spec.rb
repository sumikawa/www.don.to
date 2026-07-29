require 'spec_helper'
require_relative '../../helpers/secret_page_helpers'

RSpec.describe SecretPageHelpers do
  let(:helper) { Class.new { include SecretPageHelpers }.new }

  around do |example|
    previous = ENV.fetch('SECRET_PAGE_PASSWORD', nil)
    ENV['SECRET_PAGE_PASSWORD'] = 'test-password'
    example.run
    ENV['SECRET_PAGE_PASSWORD'] = previous
  end

  describe '#encrypted_secret_page_payload' do
    it 'encrypts a payload that can be decrypted with the same password' do
      payload = helper.encrypted_secret_page_payload('<p>secret body</p>')

      expect(payload).to include(
        v: 1,
        kdf: 'PBKDF2-HMAC-SHA256',
        cipher: 'AES-256-GCM',
        iterations: 210_000
      )

      decrypted = helper.decrypt_secret_page_payload(payload.transform_keys(&:to_s), 'test-password')
      expect(decrypted).to eq('<p>secret body</p>')
    end

    it 'produces different ciphertexts for the same plaintext' do
      first = helper.encrypted_secret_page_payload('<p>secret body</p>')
      second = helper.encrypted_secret_page_payload('<p>secret body</p>')

      expect(first[:ciphertext]).not_to eq(second[:ciphertext])
    end
  end

  describe '#secret_page_password!' do
    it 'raises when the build password is missing' do
      ENV.delete('SECRET_PAGE_PASSWORD')
      expect { helper.secret_page_password! }.to raise_error(RuntimeError, /SECRET_PAGE_PASSWORD/)
    end
  end
end
