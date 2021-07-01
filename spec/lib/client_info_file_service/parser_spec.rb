require 'spec_helper'

RSpec.describe ClientInfoFileService::Parser do
  describe '#initialize' do
    it 'should set instance variables' do
      service = ClientInfoFileService::Parser.new(['input.csv'])
      expect(service.instance_variable_get('@input')).to eq ['input.csv']
    end
  end

  describe '#valid' do
    it 'should return true if instance variable is empty' do
      expect(ClientInfoFileService::Parser.new().valid).to eq true
    end

    it 'should return false if instance variable is not single' do
      expect(STDERR).to receive(:puts).with('Only accept 1 input file')
      expect(ClientInfoFileService::Parser.new(['a', 'b']).valid).to eq false
    end

    it 'should return false if file path is invalid' do
      expect_any_instance_of(ClientInfoFileService::Parser).to receive(:validate_input_file).with('a.csv').at_least(:once).and_return 'invalid'
      expect(STDERR).to receive(:puts).with('invalid')
      expect(ClientInfoFileService::Parser.new(['a.csv']).valid).to eq false
    end

    it 'should return false if file header is invalid' do
      expect_any_instance_of(ClientInfoFileService::Parser).to receive(:validate_input_file).with('a.csv').at_least(:once)
      expect_any_instance_of(ClientInfoFileService::Parser).to receive(:validate_input_file_header).with('a.csv').at_least(:once).and_return 'invalid'
      expect(STDERR).to receive(:puts).with('invalid')
      expect(ClientInfoFileService::Parser.new(['a.csv']).valid).to eq false
    end

    it 'should return true if file is valid' do
      expect_any_instance_of(ClientInfoFileService::Parser).to receive(:validate_input_file).with('a.csv').at_least(:once)
      expect_any_instance_of(ClientInfoFileService::Parser).to receive(:validate_input_file_header).with('a.csv').at_least(:once)
      expect(ClientInfoFileService::Parser.new(['a.csv']).valid).to eq true
    end
  end

  describe '#parse' do
    it 'should parse gets' do
      allow_any_instance_of(Kernel).to receive(:gets).and_return('gets', nil)
      expect_any_instance_of(ClientInfoFileService::Parser).to receive(:parse_content)
      ClientInfoFileService::Parser.new().parse
    end
  end

  describe '#validate_input_file' do
    it 'should return message if file not exist' do
      expect(File).to receive(:file?).with('a.csv').and_return false
      expect(ClientInfoFileService::Parser.new(['a.csv']).send(:validate_input_file, 'a.csv')).to eq 'Cannot find file a.csv'
    end

    it 'should return message if not a csv file' do
      expect(File).to receive(:file?).with('a.csv').and_return true
      expect(File).to receive(:extname).with('a.csv').and_return false
      expect(ClientInfoFileService::Parser.new(['a.csv']).send(:validate_input_file, 'a.csv')).to eq 'Please provide a CSV file'
    end
  end

  describe '#validate_input_file_header' do
    before do
      @path = 'a.csv'
      @file = double('File')
      expect(File).to receive(:read).with(@path).and_return @file
    end

    it 'should return message if header not same' do
      expect(CSV).to receive(:parse).with(@file).and_return ['test']
      expect(ClientInfoFileService::Parser.new([@path]).send(:validate_input_file_header, @path)).to eq "Header should same as [\"Email\", \"First Name\", \"Last Name\", \"Residential Address Street\", \"Residential Address Locality\", \"Residential Address State\", \"Residential Address Postcode\", \"Postal Address Street\", \"Postal Address Locality\", \"Postal Address State\", \"Postal Address Postcode\"]"
    end

    it 'should return nil if header is same' do
      expect(CSV).to receive(:parse).with(@file).and_return [['Email', 'First Name', 'Last Name', 'Residential Address Street', 'Residential Address Locality', 'Residential Address State', 'Residential Address Postcode', 'Postal Address Street', 'Postal Address Locality', 'Postal Address State', 'Postal Address Postcode']]
      expect(ClientInfoFileService::Parser.new([@path]).send(:validate_input_file_header, @path)).to eq nil
    end
  end

  describe '#parse_content' do
    before do
      @line = "colton_tromp@gmail.com,Darcy,Waters,8540 Charli Summit,AIRLIE BEACH,QLD,4802,376 Williamson Hill,ARTHUR RIVER,WA,6315\r\n"
      @geo_result = double('Geocoder')
    end

    it 'should return nil if current line is header' do
      expect_any_instance_of(Kernel).not_to receive(:puts)
      ClientInfoFileService::Parser.new().send(:parse_content, ClientInfoFileService::Parser::HEADER.join(','))
    end

    it 'should return nil if email is blank' do
      line = ",Darcy,Waters,8540 Charli Summit,AIRLIE BEACH,QLD,4802,376 Williamson Hill,ARTHUR RIVER,WA,6315\r\n"
      expect_any_instance_of(Kernel).not_to receive(:puts)
      ClientInfoFileService::Parser.new().send(:parse_content, line)
    end

    it 'should return nil if first name is blank' do
      line = "colton_tromp@gmail.com,,Waters,8540 Charli Summit,AIRLIE BEACH,QLD,4802,376 Williamson Hill,ARTHUR RIVER,WA,6315\r\n"
      expect_any_instance_of(Kernel).not_to receive(:puts)
      ClientInfoFileService::Parser.new().send(:parse_content, line)
    end

    it 'should return nil if last name is blank' do
      line = "colton_tromp@gmail.com,Waters,,8540 Charli Summit,AIRLIE BEACH,QLD,4802,376 Williamson Hill,ARTHUR RIVER,WA,6315\r\n"
      expect_any_instance_of(Kernel).not_to receive(:puts)
      ClientInfoFileService::Parser.new().send(:parse_content, line)
    end

    it 'should return nil if residential addresses is blank' do
      line = "colton_tromp@gmail.com,Darcy,Waters,,,,,376 Williamson Hill,ARTHUR RIVER,WA,6315\r\n"
      expect_any_instance_of(Kernel).not_to receive(:puts)
      ClientInfoFileService::Parser.new().send(:parse_content, line)
    end

    it 'should return nil if postal addresses is blank' do
      line = "colton_tromp@gmail.com,Darcy,Waters,8540 Charli Summit,AIRLIE BEACH,QLD,4802,,,,\r\n"
      expect_any_instance_of(Kernel).not_to receive(:puts)
      ClientInfoFileService::Parser.new().send(:parse_content, line)
    end 

    it 'should return nil if invalid residential location/postcode pair' do
      expect(Geocoder).to receive(:search).with('8540 Charli Summit, AIRLIE BEACH, QLD, AU').and_return [@geo_result]
      expect(Geocoder).to receive(:search).with('376 Williamson Hill, ARTHUR RIVER, WA, AU').and_return [@geo_result]
      expect(@geo_result).to receive(:postal_code).and_return '5000'
      expect_any_instance_of(Kernel).not_to receive(:puts)
      ClientInfoFileService::Parser.new().send(:parse_content, @line)
    end

    it 'should return nil if invalid postal location/postcode pair' do
      geo_result = double('Geocoder')
      expect(Geocoder).to receive(:search).with('8540 Charli Summit, AIRLIE BEACH, QLD, AU').and_return [@geo_result]
      expect(Geocoder).to receive(:search).with('376 Williamson Hill, ARTHUR RIVER, WA, AU').and_return [geo_result]
      expect(@geo_result).to receive(:postal_code).and_return '4802'
      expect(geo_result).to receive(:postal_code).and_return '5000'
      expect_any_instance_of(Kernel).not_to receive(:puts)
      ClientInfoFileService::Parser.new().send(:parse_content, @line)
    end

    it 'should return nil if cannot fetch GEO coordinates' do
      expect(Geocoder).to receive(:search).with('8540 Charli Summit, AIRLIE BEACH, QLD, AU').and_return []
      expect_any_instance_of(Kernel).not_to receive(:puts)
      ClientInfoFileService::Parser.new().send(:parse_content, @line)
    end

    it 'should return all info with GEO coordinates' do
      geo_result = double('Geocoder')
      expect(Geocoder).to receive(:search).with('8540 Charli Summit, AIRLIE BEACH, QLD, AU').and_return [@geo_result]
      expect(Geocoder).to receive(:search).with('376 Williamson Hill, ARTHUR RIVER, WA, AU').and_return [geo_result]
      expect(@geo_result).to receive(:postal_code).and_return '4802'
      expect(geo_result).to receive(:postal_code).and_return '6315'
      expect(@geo_result).to receive(:coordinates).and_return ['-34', '160']
      expect(geo_result).to receive(:coordinates).and_return ['-34', '120']
      expect_any_instance_of(Kernel).to receive(:puts).with("colton_tromp@gmail.com, Darcy, Waters, 8540 Charli Summit, AIRLIE BEACH, QLD, 4802, -34, 160, 376 Williamson Hill, ARTHUR RIVER, WA, 6315, -34, 120")
      ClientInfoFileService::Parser.new().send(:parse_content, @line)
    end
  end
end
