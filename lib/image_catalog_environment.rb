# frozen_string_literal: true

require 'dotenv'

module ImageCatalogEnvironment
  def self.load
    Dotenv.load(File.join(Dir.home, '.env'))
  end
end
