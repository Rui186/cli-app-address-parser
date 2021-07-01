module ClientInfoFileService  
  class Parser
    require 'csv'
    require 'geocoder'

    HEADER = ['Email', 'First Name', 'Last Name', 'Residential Address Street', 'Residential Address Locality', 'Residential Address State', 'Residential Address Postcode', 'Postal Address Street', 'Postal Address Locality', 'Postal Address State', 'Postal Address Postcode']

    def initialize(input = '')
      @input = input
    end

    def valid
      return true if @input.empty?

      if @input.size > 1
        STDERR.puts 'Only accept 1 input file'
        return false
      end

      if !validate_input_file(@input.first).nil?
        STDERR.puts validate_input_file(@input.first)
        return false
      end
            
      if !validate_input_file_header(@input.first).nil?
        STDERR.puts validate_input_file_header(@input.first)
        return false
      end

      true
    end

    def parse
      while gets
        parse_content(gets)
      end
    end

    private

    def validate_input_file(file)
      return "Cannot find file #{file}" unless File.file?(file)
      return 'Please provide a CSV file' unless File.extname(file) == '.csv'
    end

    def validate_input_file_header(file)
      file = File.read(file)
      table = CSV.parse(file)
      return if table.first == HEADER
      "Header should same as #{HEADER}"
    end
    
    def parse_content(line)
      line = line.strip.split(',')

      return if line == HEADER

      line = line.reject{ |i| i.to_s.empty? }
      # blank value
      return if line.size < HEADER.size

      residential_address = (line[3, 3] << 'AU').join(', ')
      residential_geo_result = Geocoder.search(residential_address).first
      # cannot fetch GEO coordinates
      return if residential_geo_result.nil?

      postal_address = (line[7, 3] << 'AU').join(', ')
      postal_geo_result = if residential_address == postal_address
                            residential_geo_result
                          else
                            postal_geo_result = Geocoder.search(postal_address).first
                          end
      # cannot fetch GEO coordinates
      return if postal_geo_result.nil?

      # invalid location/postcode pair
      return if residential_geo_result.postal_code != line[6]
      return if postal_geo_result.postal_code != line[10]

      # latitude and longitude
      residential_geo_coordinates = residential_geo_result.coordinates
      postal_geo_coordinates = postal_geo_result.coordinates

      output_line = line[0, 7] + residential_geo_coordinates + line[7, 4] + postal_geo_coordinates

      puts output_line.join(', ')
    end
  end
end