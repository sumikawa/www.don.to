require 'spec_helper'
require 'tmpdir'
require_relative '../../lib/image_catalog_command'

RSpec.describe ImageCatalogCommand do
  around do |example|
    Dir.mktmpdir do |root|
      @root = root
      FileUtils.mkdir_p(File.join(root, 'source/diary/2026'))
      FileUtils.mkdir_p(File.join(root, 'data'))
      FileUtils.mkdir_p(File.join(root, 'images/diary'))
      %w[0101-a 0102-b].each { |name| File.write(File.join(root, "source/diary/2026/#{name}.html.md.erb"), '') }
      example.run
    end
  end

  let(:site) { { 'cacherootdir' => '/cache', 'imagerootdir' => File.join(@root, 'images') } }
  let(:command) { described_class.new(root: @root, site: site) }
  let(:catalog) { instance_double(ImageCatalog) }
  let(:generator) { instance_double(ImageCacheGenerator, generate: nil) }
  let(:regenerator) { instance_double(ImageCacheRegenerator, regenerate: nil) }

  before do
    allow(ImageCatalog).to receive(:new).and_return(catalog)
    allow(ImageCacheGenerator).to receive(:new).and_return(generator)
    allow(ImageCacheRegenerator).to receive(:new).and_return(regenerator)
    allow(ImageCatalogTarget).to receive(:new) do |article, **_options|
      double('target', pattern: File.basename(article))
    end
  end

  it 'syncs a year by generating caches and updating each article catalog' do
    allow(command).to receive(:image_articles).and_return(%w[first second])
    expect(ImageCacheGenerator).to receive(:new).with(site: site, strict_video: false).twice.and_return(generator)
    expect(generator).to receive(:generate).twice
    expect(catalog).to receive(:sync?).twice.and_return(true)
    expect(command.run?(%w[sync 2026])).to be true
  end

  it 'checks videos strictly for an article sync' do
    expect(ImageCacheGenerator).to receive(:new).with(site: site, strict_video: true).and_return(generator)
    expect(catalog).to receive(:sync?).and_return(true)
    expect(command.run?(['sync', 'source/diary/2026/0101-a.html.md.erb'])).to be true
  end

  it 'shows detailed progress only with -v' do
    allow(catalog).to receive(:sync?) do
      puts 'Scanning: details'
      true
    end
    expect { command.run?(%w[sync 2026]) }.to output(%r{Syncing: 2026.*Completed: 2/2 articles}m).to_stdout
    expect { command.run?(%w[sync 2026]) }.not_to output(/Scanning: details/).to_stdout
    expect { command.run?(%w[sync 2026 -v]) }.to output(/Scanning: details/).to_stdout
  end

  it 'hides cache regeneration and positional catalog details by default' do
    allow(regenerator).to receive(:regenerate) { puts 'Regenerated cache: details' }
    article = 'source/diary/2026/0101-a.html.md.erb'
    expect { command.run?(['cache', article]) }.not_to output(/Regenerated cache: details/).to_stdout
    expect { command.run?(['cache', article, '-v']) }.to output(/Regenerated cache: details/).to_stdout

    allow(catalog).to receive(:sync?) do
      puts 'Requesting Dropbox link: details'
      true
    end
    expect { command.run?(['2026']) }.not_to output(/Requesting Dropbox link: details/).to_stdout
    expect { command.run?(%w[2026 -v]) }.to output(/Requesting Dropbox link: details/).to_stdout
  end

  it 'accepts repository-relative article paths for forced cache regeneration' do
    article = 'source/diary/2026/0101-a.html.md.erb'
    expect(ImageCatalogTarget).to receive(:new)
      .with(File.join(@root, article), root: @root, site: site, allow_missing_original: true)
      .and_return(double('target'))
    expect(regenerator).to receive(:regenerate).once
    Dir.chdir(File.join(@root, 'data')) do
      expect(command.run?(['cache', article])).to be true
    end
  end

  it 'previews stale cache and YAML cleanup for an article without media' do
    article = 'source/diary/2026/0101-a.html.md.erb'
    cache_dir = File.join(@root, 'cache/diary/2026/0101-a')
    FileUtils.mkdir_p(cache_dir)
    FileUtils.mkdir_p(File.join(@root, 'data/image'))
    File.write(File.join(cache_dir, 'old.jpg'), 'old')
    File.write(File.join(@root, 'data/image/2026.yml'), YAML.dump('0101-a' => { 'old.jpg' => 'url' }))
    allow(ImageCatalogTarget).to receive(:new).and_call_original
    site['cacherootdir'] = File.join(@root, 'cache')
    expect(ImageCacheGenerator).not_to receive(:new)
    expect(catalog).not_to receive(:sync?)
    expect { command.run?(['sync', article, '--dry-run']) }
      .to output(/Delete cache:.*old.jpg.*Remove YAML: old.jpg/m).to_stdout
    expect(File.exist?(File.join(cache_dir, 'old.jpg'))).to be true
    expect(YAML.safe_load_file(File.join(@root, 'data/image/2026.yml'))).to have_key('0101-a')
  end

  it 'cleans cache and YAML for an article without original media' do
    article = 'source/diary/2026/0101-a.html.md.erb'
    cache_dir = File.join(@root, 'cache/diary/2026/0101-a')
    FileUtils.mkdir_p(cache_dir)
    FileUtils.mkdir_p(File.join(@root, 'data/image'))
    cache_file = File.join(cache_dir, 'old.jpg')
    File.write(cache_file, 'old')
    catalog_file = File.join(@root, 'data/image/2026.yml')
    File.write(catalog_file, YAML.dump('0101-a' => { 'old.jpg' => 'url' }))
    site['cacherootdir'] = File.join(@root, 'cache')
    allow(ImageCatalogTarget).to receive(:new).and_call_original
    allow(ImageCatalog).to receive(:new).and_call_original
    expect(command.run?(['sync', article])).to be true
    expect(File.exist?(cache_file)).to be false
    expect(YAML.safe_load_file(catalog_file)).not_to have_key('0101-a')
  end

  it 'rejects a missing original media root before syncing' do
    FileUtils.remove_dir(File.join(@root, 'images/diary'))
    expect { command.run?(%w[sync 2026]) }.to raise_error(ArgumentError, /Original media root not found/)
  end

  it 'continues after an error and reports overall failure' do
    expect(catalog).to receive(:sync?).with('0101-a.html.md.erb', target: anything).and_raise(ArgumentError, 'missing source')
    expect(catalog).to receive(:sync?).with('0102-b.html.md.erb', target: anything).and_return(true)
    expect(command.run?(%w[sync 2026])).to be false
  end

  it 'continues after pending uploads without reporting overall success' do
    expect(catalog).to receive(:sync?).with('0101-a.html.md.erb', target: anything).and_return(false)
    expect(catalog).to receive(:sync?).with('0102-b.html.md.erb', target: anything).and_return(true)
    expect(command.run?(%w[sync 2026])).to be false
  end

  it 'removes the old options and preserves the positional year mode' do
    expect { command.run?(['-u', 'source/diary/2026/0101-a.html.md.erb']) }.to raise_error(ArgumentError, /Usage/)
    expect { command.run?(%w[-p 2026]) }.to raise_error(ArgumentError, /Usage/)
    expect { command.run?(%w[2025 2026]) }.to raise_error(ArgumentError, /Usage/)
    expect(catalog).to receive(:sync?).with('*/2026/**/*.*').and_return(true)
    expect(command.run?(['2026'])).to be true
  end

  it 'prints help without creating a catalog or changing files' do
    expect(ImageCatalog).not_to receive(:new)
    expect { command.run?(['--help']) }.to output(/Options:.*sync YYYY\|ARTICLE/m).to_stdout
    expect(command.run?(['-h'])).to be true
  end
end
