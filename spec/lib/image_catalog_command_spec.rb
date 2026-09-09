require 'spec_helper'
require 'tmpdir'
require_relative '../../lib/image_catalog_command'

RSpec.describe ImageCatalogCommand do
  around do |example|
    Dir.mktmpdir do |root|
      @root = root
      FileUtils.mkdir_p(File.join(root, 'source/diary/2026'))
      FileUtils.mkdir_p(File.join(root, 'data'))
      %w[0101-a 0102-b].each { |name| File.write(File.join(root, "source/diary/2026/#{name}.html.md.erb"), '') }
      example.run
    end
  end

  let(:command) { described_class.new(root: @root, site: { 'cacherootdir' => '/cache' }) }
  let(:catalog) { instance_double(ImageCatalog) }

  before do
    allow(ImageCatalog).to receive(:new).and_return(catalog)
    allow(ImageCatalogTarget).to receive(:new) do |article, **_options|
      double('target', pattern: File.basename(article))
    end
  end

  it 'processes multiple files and deduplicates repeated arguments' do
    expect(catalog).to receive(:sync?).with('0101-a.html.md.erb', target: anything).once.and_return(true)
    expect(catalog).to receive(:sync?).with('0102-b.html.md.erb', target: anything).once.and_return(true)
    expect(command.run?(['-u', 'source/diary/2026/0101-a.html.md.erb', 'source/diary/2026/0102-b.html.md.erb',
                         'source/diary/2026/0101-a.html.md.erb'])).to be true
  end

  it 'expands a quoted repository-relative glob from the data directory' do
    expect(catalog).to receive(:sync?).with('0101-a.html.md.erb', target: anything).and_return(true)
    expect(catalog).to receive(:sync?).with('0102-b.html.md.erb', target: anything).and_return(true)
    Dir.chdir(File.join(@root, 'data')) do
      expect(command.run?(['-u', 'source/diary/2026/*.erb'])).to be true
    end
  end

  it 'continues after an error and reports overall failure' do
    expect(catalog).to receive(:sync?).with('0101-a.html.md.erb', target: anything).and_raise(ArgumentError, 'missing source')
    expect(catalog).to receive(:sync?).with('0102-b.html.md.erb', target: anything).and_return(true)
    expect(command.run?(['-u', 'source/diary/2026/*.erb'])).to be false
  end

  it 'continues after pending uploads without reporting overall success' do
    expect(catalog).to receive(:sync?).with('0101-a.html.md.erb', target: anything).and_return(false)
    expect(catalog).to receive(:sync?).with('0102-b.html.md.erb', target: anything).and_return(true)
    expect(command.run?(['-u', 'source/diary/2026/*.erb'])).to be false
  end

  it 'requires at least one update argument and preserves single-year mode' do
    expect { command.run?(['-u']) }.to raise_error(ArgumentError, /Usage/)
    expect { command.run?(%w[2025 2026]) }.to raise_error(ArgumentError, /Usage/)
    expect(catalog).to receive(:sync?).with('*/2026/**/*.*').and_return(true)
    expect(command.run?(['2026'])).to be true
  end
end
