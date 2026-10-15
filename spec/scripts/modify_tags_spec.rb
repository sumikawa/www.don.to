require 'spec_helper'

load File.expand_path('../../scripts/modify_tags.rb', __dir__)

RSpec.describe 'modify_tags' do
  it 'translates every Japanese tag currently used in diary front matter' do
    JAPANESE_TAGS.each do |japanese, english|
      expect(transform_tags([japanese], '')).to eq([english])
    end

    tags = Dir.glob('source/diary/**/*.md.erb').flat_map do |file|
      extract_original_tags(File.read(file)) || []
    end
    japanese_tags = tags.grep(JAPANESE_CHARACTERS).uniq

    expect(japanese_tags - JAPANESE_TAGS.keys).to be_empty
    expect(transform_tags(japanese_tags, '')).to all(satisfy { |tag| !tag.match?(JAPANESE_CHARACTERS) })
  end

  it 'deduplicates translated tags and applies existing redundancy rules' do
    expect(transform_tags(%w[キャンプ camp 公園 nature], '')).to eq(%w[camp park])
  end

  it 'rejects an unrecognized Japanese tag instead of leaving it untranslated' do
    expect { transform_tags(['未知のタグ'], '') }.to raise_error(ArgumentError, /未知のタグ/)
  end
end
