require 'spec_helper'
require_relative '../../helpers/site_helpers'

RSpec.describe SiteHelpers do
  let(:helper) { Class.new { include SiteHelpers }.new }

  before do
    allow(helper).to receive(:data).and_return(app.data)
  end

  describe '#localhost?' do
    context 'when hostname contains mbair' do
      before do
        allow(helper).to receive(:`).with('hostname').and_return("mbair.local\n")
      end

      it 'returns true' do
        expect(helper.localhost?).to be true
      end
    end

    context 'when hostname does not contain mbair' do
      before do
        allow(helper).to receive(:`).with('hostname').and_return("server.example.com\n")
      end

      it 'returns false' do
        expect(helper.localhost?).to be false
      end
    end
  end

  describe '#thisyear' do
    it 'delegates to data.year.thisyear' do
      expect(helper.thisyear).to eq(app.data.year.thisyear)
    end
  end
end
