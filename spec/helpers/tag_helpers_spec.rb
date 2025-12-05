require 'spec_helper'
require_relative '../../helpers/tag_helpers'

RSpec.describe TagHelpers do
  let(:helper) { Class.new { include TagHelpers }.new }

  describe '#tags_list' do
    let(:test_files) do
      {
        'source/diary/2025/0101-test.html.md.erb' => "---\ntitle: Test\ntags: ruby, rails\n---\nContent",
        'source/diary/2025/0102-test.html.md.erb' => "---\ntitle: Test2\ntags: ruby, python\n---\nContent",
        'source/diary/2025/0103-test.html.md.erb' => "---\ntitle: Test3\n---\nContent"
      }
    end

    before do
      allow(Dir).to receive(:glob).with('source/diary/[012]*/**/*.html.md.erb').and_return(test_files.keys)
      allow(File).to receive(:read) { |path| test_files[path] }
    end

    it 'returns a hash of tags with file paths' do
      tags = helper.tags_list
      expect(tags).to be_a(Hash)
      expect(tags['ruby']).to contain_exactly('source/diary/2025/0101-test.html.md.erb', 'source/diary/2025/0102-test.html.md.erb')
      expect(tags['rails']).to contain_exactly('source/diary/2025/0101-test.html.md.erb')
      expect(tags['python']).to contain_exactly('source/diary/2025/0102-test.html.md.erb')
    end

    it 'normalizes tags to lowercase' do
      allow(File).to receive(:read).and_return("---\ntitle: Test\ntags: Ruby, RAILS\n---\nContent")
      tags = helper.tags_list
      expect(tags).to have_key('ruby')
      expect(tags).to have_key('rails')
    end

    it 'strips whitespace from tags' do
      allow(File).to receive(:read).and_return("---\ntitle: Test\ntags:  ruby  ,  rails  \n---\nContent")
      tags = helper.tags_list
      expect(tags).to have_key('ruby')
      expect(tags).to have_key('rails')
    end

    it 'skips files without tags' do
      tags = helper.tags_list
      expect(tags.values.flatten).not_to include('source/diary/2025/0103-test.html.md.erb')
    end

    it 'caches the result' do
      expect(Dir).to receive(:glob).once.and_return([])
      helper.tags_list
      helper.tags_list
    end
  end
end
