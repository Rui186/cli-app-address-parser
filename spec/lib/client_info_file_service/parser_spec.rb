require 'spec_helper'

RSpec.describe ClientInfoFileService::Parser do
  describe '#initialize' do
    it 'should set instance variables' do
      service = ClientInfoFileService::Parser.new(['input.csv'])
      expect(service.instance_variable_get('@input')).to eq ['input.csv']
    end
  end

  describe '#valid' do
    
  end

  describe '#parse' do

  end

  describe '#validate_input_file' do
    
  end

  describe '#validate_input_file_header' do
    
  end

  describe '#parse_content' do
    
  end
end
