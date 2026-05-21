require 'spec_helper'
require_relative '../../helpers/tag_helpers'

RSpec.describe TagHelpers do
  let(:helper) { Class.new { include TagHelpers }.new }

  describe '#tags_list' do
    let(:tags_data) do
      {
        'ruby' => ['source/diary/2025/0101-test.html.md.erb', 'source/diary/2025/0102-test.html.md.erb'],
        'rails' => ['source/diary/2025/0101-test.html.md.erb'],
        'python' => ['source/diary/2025/0102-test.html.md.erb']
      }
    end

    before do
      allow(helper).to receive(:data).and_return(double('data', tags: tags_data))
    end

    it 'returns a hash of tags with file paths' do
      tags = helper.tags_list
      expect(tags).to be_a(Hash)
      expect(tags['ruby']).to contain_exactly('source/diary/2025/0101-test.html.md.erb', 'source/diary/2025/0102-test.html.md.erb')
      expect(tags['rails']).to contain_exactly('source/diary/2025/0101-test.html.md.erb')
      expect(tags['python']).to contain_exactly('source/diary/2025/0102-test.html.md.erb')
    end

    it 'returns the tags data from Middleman data' do
      expect(helper.tags_list).to eq(tags_data)
    end
  end

  describe '#tags_for_file' do
    it 'normalizes tags to lowercase' do
      allow(File).to receive(:read).and_return("---\ntitle: Test\ntags: Ruby, RAILS\n---\nContent")
      tags = helper.send(:tags_for_file, 'source/diary/2025/0101-test.html.md.erb')
      expect(tags).to eq(%w[ruby rails])
    end

    it 'strips whitespace from tags' do
      allow(File).to receive(:read).and_return("---\ntitle: Test\ntags:  ruby  ,  rails  \n---\nContent")
      tags = helper.send(:tags_for_file, 'source/diary/2025/0101-test.html.md.erb')
      expect(tags).to eq(%w[ruby rails])
    end

    it 'returns an empty array for files without tags' do
      allow(File).to receive(:read).and_return("---\ntitle: Test\n---\nContent")
      tags = helper.send(:tags_for_file, 'source/diary/2025/0103-test.html.md.erb')
      expect(tags).to eq([])
    end
  end
end
