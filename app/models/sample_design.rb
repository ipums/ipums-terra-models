# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'csv'


####
#
# To get the _geog_setup.yml files, run things like this:
#
#  Country.where({}).each{|country| SampleDesign.to_geog_setup(country) }
#

class SampleDesign < ActiveRecord::Base

  belongs_to :country

  # Parses a sample design file (which is tab-delimited CSV) for a specified sample, returning
  # the metadata in a hashtable.  We use the CSV library as the parsed files use some of the
  # more obscure features of CSVs, such as multiline values.
  
  @@has_startup = false
  
  def self.startup
    
    unless @@has_startup
      @tag_mapping = {
          'sample_id' => [''.upcase],
          'label' => ['custom:label'.upcase],
          'description' => ['census characteristics:title'.upcase],
          'local_title' => [''.upcase],
          'is_weighted' => [''.upcase],
          'census_agency' => ['census characteristics:census agency'.upcase],
          'population_universe' => ['census characteristics:population universe'.upcase],
          'de_jure_or_de_facto' => ['census characteristics:de jure or de facto'.upcase],
          'enumeration_unit' => ['census characteristics:enumeration unit'.upcase],
          'census_start_date' => ['census characteristics:census day'.upcase],
          'census_end_date' => [''.upcase],
          'fieldwork_start_period' => ['census characteristics:census day'.upcase],
          'fieldwork_end_period' => [''.upcase],
          'enumeration_forms' => ['census characteristics:enumeration forms'.upcase],
          'type_of_fieldwork' => ['census characteristics:type of fieldwork'.upcase],
          'respondent' => ['census characteristics:respondent'.upcase],
          'coverage' => ['census characteristics:coverage'.upcase],
          'undercount' => ['census characteristics:undercount'.upcase],
          'undercount_notes' => [''.upcase],

          'microdata_source' => ['microdata sample characteristics:microdata source'.upcase],
          'long_form_sample_design' => [''.upcase],
          'mpc_sample_design' => [''.upcase],
          'sample_unit' => ['microdata sample characteristics:sample unit'.upcase],
          'sample_fraction' => ['microdata sample characteristics:sample fraction'.upcase],
          'sample_fraction_notes' => [''.upcase],
          'sample_size' => ['microdata sample characteristics:sample size (person records)'.upcase],
          'sample_weights' => ['microdata sample characteristics:sample weights'.upcase],
          'sample_characteristics_notes' => [''.upcase],
          'sample_general_notes' => [''.upcase],

          'has_dwellings' => ['units identified:dwellings'.upcase],
          'has_dwellings_note' => [''.upcase],
          'has_vacant_units' => ['Units identified:Vacant units'.upcase, 'Units identified:Vacant dwellings'.upcase],
          'has_vacant_units_note' => [''.upcase],
          'has_closed_units' => [''.upcase],
          'has_closed_units_note' => [''.upcase],
          'smallest_geography' => ['units identified:smallest geography'.upcase],

          'has_households' => ['units identified:households'.upcase],
          'has_households_note' => [''.upcase],
          'has_families' => ['units identified:families'.upcase],
          'has_families_note' => [''.upcase],
          'has_individuals' => ['units identified:individuals'.upcase],
          'has_individuals_note' => [''.upcase],
          'has_group_quarters' => ['Units identified:Group quarters'.upcase, 'Units identified:Group quarters (Collective households)'.upcase],
          'has_group_quarters_note' => [''.upcase],
          'has_indigenous_pop' => ['units identified:indigenous population'.upcase],
          'has_indigenous_pop_note' => [''.upcase],
          'has_special_pop' => ['units identified:special populations'.upcase],
          'has_special_pop_note' => [''.upcase],
          'units_notes' => [''.upcase],
          'identification_general_notes' => [''.upcase],

          'unit_definition_household' => ['Unit definitions:Households'.upcase, 'Unit definitions:Private Household'.upcase],
          'unit_definition_family' => ['unit definitions:families'.upcase],
          'unit_definition_group_quarters' => ['Unit definitions:Group quarters'.upcase, 'Unit definitions:Group Quarters (Collective households)'.upcase],
          'unit_definition_dwelling' => ['unit definitions:dwellings'.upcase],
          'unit_definition_homeless_population' => [''.upcase],
          'unit_definition_institution' => [''.upcase],
          'unit_definition_institutional_population' => [''.upcase],
          'unit_definition_notes' => [''.upcase],
          'unit_definition_general_notes' => [''.upcase]
      }

      @country_abbrev_lookup = Hash[Country.where({}).order(:short_name).map{|country| [country.short_name, country.full_name]}]
    
      @@has_startup = true
    end
    
  end
  
  def self.parse(string)
    if string =~ /\A[Yy]es\Z/
      # is it a 'yes'?
      true
    elsif string =~ /\A[Nn]o\Z/ or string =~ /Not available in microdata sample/ or string =~ /---/
      #is it a 'no'?
      false
    elsif string =~ /\A\d+(.\d+)?%\Z/
      # is it a percentage? (which could look like 100% or like 10.5%)
      numeric_portion = string.chop
      (numeric_portion.to_i) / 100.0
    elsif string =~ /\A\d+\Z/ or string =~ /\A(\d{1,3},?)+\Z/
      # is it an int with or without commas?
      numeric_portion = string.gsub(',', '')
      numeric_portion.to_i
    else
      # just return the argument itself.
      string
    end
  end

  # country code is in the form <2-char country id><4-digit year><sample_id>
  # such as us1990a for the US 1990 census.
  # returns a hash with keys of :abbrev, :country and :year
  # or nil if the name doesn't match the regex.
  def self.parse_sample_id(name)
    # $stderr.puts name
    code_regex = /(?<abbrev>[a-z]{2})(?<year>\d{4})(?<sample_id>[a-z])/
    match = code_regex.match(name)
    if match.nil?
      nil
    else
      # $stderr.puts "==> #{match[:abbrev]}"
      {:abbrev => match[:abbrev], :year => match[:year], :country => @country_abbrev_lookup[match[:abbrev]]}
    end
  end

  # returns the dataset entry as a hash ready to be converted to YAML.
  def self.construct_sample_entry(possible_tags, name, contents)
    sampledesc_hash = {'sample_id' => name}
    output = {}
    possible_tags.each { |key, value|
      if value.count > 0
        sampledesc_key = value.detect { |sampledesc_key| contents.has_key? (sampledesc_key) }
        unless sampledesc_key.nil?
          unless contents[sampledesc_key].nil?
            sampledesc_hash[key] = parse(contents[sampledesc_key].strip)
          end
        end
      end

      output = {'terrapop_samples' => [sampledesc_hash]}
    }
    output
  end

  # Return an array of sample_geog_level instances.
  # For now, just construct national and GEOLEV1 entries here. As more are added, add more.
  #
  def self.construct_sample_geog_levels(sample_id, abbrev, name, year, contents)
    national = {
        'terrapop_sample_id' => "#{name} #{year}",
        'label' => "#{name}: National, #{year}",
        'internal_code' => "#{sample_id}_NAT",
        'geolink_variable_id' => 'CNTRY',
        'country_level_id' => [{'geog_unit_id' => 'NAT'}, {'country_id' => "#{abbrev}"}]
    }
    geolev1 = {
        'terrapop_sample_id' => "#{name} #{year}",
        'label' => "#{name}: First Level (Harmonized), #{year}",
        'internal_code' => "#{sample_id}_HFLAD",
        'geolink_variable_id' => 'GEOLEV1',
        'country_level_id' => [{'geog_unit_id' => 'HFLAD'}, {'country_id' => "#{abbrev}"}]
    }
    [national, geolev1]

  end
  
  def self.to_geog_setup(country)
    
    unless country.kind_of? Country
      raise "Object passed to SampleDesign::to_geog_setup must be of type Country"
    end
    
    sd = self.where({:country_id => country.id}).first
    
    if sd.nil?
      $stderr.puts "==> country_id #{country.id} [#{country.full_name}] not found for SampleDesign"
    else

      startup

      column = -1
      cat    = key = ''
      result = {}
    
      contents = nil
    
      begin
        contents = CSV.parse(sd.document, {headers: true, col_sep: "\t", encoding: "iso-8859-1:utf-8"}) # CSV.read(path, {headers: true, col_sep: "\t", encoding: "iso-8859-1:utf-8"})
      rescue Exception => e
        throw e
      end
    
      unless contents.nil?
        # now flip it over.

        # first, drop the first two elements from the header to get the dataset names.
        dataset_titles = contents.headers
        dataset_titles.shift
        dataset_titles.shift

        # make a hash of hashes to hold the flipped table
        datasets = {}
        # and set up the sample label for each entry, initialized with the label field.
        dataset_titles.each { |ds|
          label_info = parse_sample_id(ds)
          unless label_info.nil?
            datasets[ds] = {'CUSTOM:LABEL' => "#{label_info[:country]} #{label_info[:year]}"}
          end
        }

        # now run through the rows of the CSV and build out the dataset sample descriptions
        category = 'heading'
        contents.each { |row|
          
          unless row['item'].nil?
            # puts row.inspect
            this_field = row['item'].strip
            this_category = row['heading']
            category = this_category.strip unless this_category.nil? or this_category.empty?

            field = "#{category}:#{this_field}".upcase # get the field heading

            # and then get the value of that field heading for each dataset,
            # and put it into the appropriate subhash in the datasets hash.
            dataset_titles.each { |ds|
              if datasets.has_key? ds
                datasets[ds][field] = row[ds]
              end
            }
          end
          
        }

        datasets.each { |name, contents|
          $stderr.puts " +++ Working on dataset[#{name}]...".color(:green)
          File.open(File.join(Rails.root.to_s, "data/geog_setup", "#{name}_geog_setup.yml"), 'w+') {|file|
            $stderr.puts " +++ Writing #{file.path}..."
            sample_info = parse_sample_id(name)
            terrapop_sample = construct_sample_entry(@tag_mapping, name, contents)
            terrapop_sample['terrapop_samples'][0]['short_country_name'] = country.short_name
            terrapop_sample['terrapop_samples'][0]['year'] = terrapop_sample['terrapop_samples'][0]['sample_id'][2,4].to_i
            # $stderr.puts terrapop_sample.to_s
            geog_info = construct_sample_geog_levels(name, sample_info[:abbrev], sample_info[:country],sample_info[:year], contents)
            terrapop_sample['sample_geog_levels'] = geog_info
            file.puts terrapop_sample.to_yaml
          }
        }
    
        {status: :OK}
      else
        {status: :FAILED, message: "#{country.full_name} failed to produce geog_setup yaml..."}
      end
    end
  end
  
  def self.fields(sample)
    
    unless sample.kind_of? Sample
      raise "Object passed to SampleDesign::fields must be of type Sample"
    end
    
    sd = self.where({:country_id => sample.country_id}).first
    
    if sd.nil?
      raise "country_id #{sample.country_id} not found for SampleDesign"
    end

    column = -1
    cat    = key = ''
    result = {}

    CSV.parse(sd.document, :col_sep => "\t", :row_sep => "\r\n").each_with_index do |record, record_no|
      record.each_with_index do |field, field_no|
        next if field.nil?
        field.strip!
        case record_no
          when 0 then column = field_no if field == sample.name # find the sample's column in the first line
          else # all other lines, build the result hashtable
            case field_no
              when 0 then (cat = field) unless field.empty?
              when 1 then (key = cat + ':' + field) unless field.empty?
              when column then result[key] = field
            end
        end
      end
    end

    result
  end

  
  
end
