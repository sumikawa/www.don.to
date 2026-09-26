# frozen_string_literal: true

module ImageVideoCache
  def self.names(path, site)
    base = File.basename(path, File.extname(path)).downcase
    ['', 'hd', 'hdtr'].flat_map do |prefix|
      ["#{prefix}#{base}.#{site.fetch('videoext')}", "#{prefix}#{base}.#{site.fetch('thumbext')}"]
    end
  end
end
