require 'spec_helper'
require 'data_magic'
require 'fixtures/data.rb'

describe DataMagic do
  it "cleans up after itself" do
    DataMagic.init(load_now: true)
    DataMagic.destroy
    DataMagic.logger.info "just destroyed"
    #expect(DataMagic.client.indices.get(index: '_all')).to be_empty
  end

  describe '.prepare_field_types' do
    it 'returns the given fields with their specified type' do
      expect(described_class.prepare_field_types({ 'state' => 'string', land_area: 'string' }))
      .to eq("state" => { :type => "string" }, :land_area => { :type => "string" })
    end

    context 'when the key is "name"' do
      it 'returns type with :index of "not_analyzed"' do
        expect(described_class.prepare_field_types({ 'state' => 'string', 'name' => 'string' }))
        .to eq({"state"=>{:type=>"string"}, "name"=>{:type=>"string", :index=>"not_analyzed"}})
      end
    end
  end

end
