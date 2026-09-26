# frozen_string_literal: true

module ImageCommandOutput
  def self.with_details(verbose)
    return yield if verbose

    File.open(File::NULL, 'w') do |sink|
      previous = $stdout
      $stdout = sink
      begin
        yield
      ensure
        $stdout = previous
      end
    end
  end
end
