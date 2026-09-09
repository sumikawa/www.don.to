require 'spec_helper'
require 'tmpdir'
require_relative '../../lib/image_catalog_target'
require_relative '../../lib/image_catalog'

RSpec.describe ImageCatalogTarget do
  around do |example|
    Dir.mktmpdir do |root|
      @root = root
      @article = 'source/diary/2026/0407-lisbon.html.md.erb'
      @original = File.join(root, 'original/diary/2026/0407-lisbon')
      @cache = File.join(root, 'cache')
      @output = File.join(root, 'data/image')
      [File.dirname(File.join(root, @article)), @original, @output, File.join(@cache, 'diary/2026/0407-lisbon')].each do |dir|
        FileUtils.mkdir_p(dir)
      end
      File.write(File.join(root, @article), 'article')
      example.run
    end
  end

  let(:site) { { 'imagerootdir' => File.join(@root, 'original'), 'thumbext' => 'jpg', 'videoext' => 'mp4' } }
  let(:target) { described_class.new(@article, root: @root, site: site) }

  it 'maps original HEIC, video and audio names to cache names' do
    %w[IMG_1.HEIC clip.MOV sound.m4a .DS_Store].each { |name| File.write(File.join(@original, name), '') }
    expect(target.filenames).to include('img_1.jpg', 'hdclip.jpg', 'hdclip.mp4', 'hdtrclip.jpg', 'clip.mp4', 'sound.m4a')
    expect(target.filenames).not_to include('.ds_store')
    Dir.chdir(File.join(@root, 'data')) { expect(target.pattern).to eq('diary/2026/0407-lisbon/*.*') }
  end

  it 'prunes deleted originals even if their cache remains and preserves other articles' do
    File.write(File.join(@original, 'kept.HEIC'), '')
    %w[kept.jpg deleted.jpg].each { |name| File.write(File.join(@cache, 'diary/2026/0407-lisbon', name), '') }
    path = File.join(@output, '2026.yml')
    File.write(path, YAML.dump('0407-lisbon' => { 'deleted.jpg' => 'old' }, 'other' => { 'x.jpg' => 'other-url' }))
    client = instance_double(DropboxLinks, close: nil)
    expect(client).to receive(:shared_url).with('/.cache/diary/2026/0407-lisbon/kept.jpg').and_return('new-url')
    catalog = ImageCatalog.new(cache_root: @cache, output_dir: @output, client: client)
    expect(catalog.sync?(target.pattern, target: target)).to be true
    expect(YAML.safe_load_file(path)).to eq('0407-lisbon' => { 'kept.jpg' => 'new-url' }, 'other' => { 'x.jpg' => 'other-url' })
  end

  it 'rejects a missing original folder instead of deleting its catalog' do
    FileUtils.rmdir(@original)
    expect { target }.to raise_error(ArgumentError, /Original media directory not found/)
  end

  it 'removes all entries when the original folder is empty' do
    path = File.join(@output, '2026.yml')
    File.write(path, YAML.dump('0407-lisbon' => { 'deleted.jpg' => 'old' }))
    client = instance_double(DropboxLinks, close: nil)
    expect(client).not_to receive(:shared_url)
    catalog = ImageCatalog.new(cache_root: @cache, output_dir: @output, client: client)
    expect(catalog.sync?(target.pattern, target: target)).to be true
    expect(YAML.safe_load_file(path)).to eq({})
  end
end
