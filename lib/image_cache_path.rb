# frozen_string_literal: true

module ImageCachePath
  def self.display(path, cache_root:)
    root = File.expand_path(cache_root)
    full_path = File.expand_path(path)
    relative = full_path.delete_prefix("#{root}/")
    return full_path if relative == full_path

    File.join(File.basename(root), relative)
  end
end
