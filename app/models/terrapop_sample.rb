# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class TerrapopSample < ActiveRecord::Base


  belongs_to :sample
  belongs_to :country

  has_many :sample_geog_levels
  has_many :sample_level_area_data_variables
  has_many :maps
  has_many :area_data_variables, through: :sample_level_area_data_variables

  has_many :sample_detail_values, through: :sample

  has_and_belongs_to_many :tags, join_table: :terrapop_samples_tags

  scope :without_nhgis, -> { where nhgis_dataset_id: nil }

  after_find :adjust_short_country_name_upcase


  def lowest_sample_geog_level
    geog_units_to_sgls = sample_geog_levels.joins(:country_level).joins("JOIN geog_units gu ON gu.id = country_levels.geog_unit_id").map{ |sgl| {sgl.country_level.geog_unit.code => sgl.id} }.reduce Hash.new, :merge
    if geog_units_to_sgls.count > 0
      if geog_units_to_sgls.keys.include? 'HSLAD'
        return SampleGeogLevel.find(geog_units_to_sgls['HSLAD'])
      elsif geog_units_to_sgls.keys.include? 'SLAD'
        return SampleGeogLevel.find(geog_units_to_sgls['SLAD'])
      elsif geog_units_to_sgls.keys.include? 'HFLAD'
        return SampleGeogLevel.find(geog_units_to_sgls['HFLAD'])
      elsif geog_units_to_sgls.keys.include? 'FLAD'
        return SampleGeogLevel.find(geog_units_to_sgls['FLAD'])
      elsif geog_units_to_sgls.keys.include? 'NAT'
        return SampleGeogLevel.find(geog_units_to_sgls['NAT'])
      end
    end
    # empty -- this is an error with metadata
    raise "No GeogUnits for TerrapopSample[#{self.id}]"
  end


  # call with the code given in GeogUnits - NAT, FLAD, etc...
  # If that code isn't found in GeogUnits, return nil.
  def map_for_level(lev_name)
    country_level = get_country_level(lev_name)
    if country_level.nil?
      nil
    else
      country_level.maps.find_by(terrapop_sample_id: id)
    end
  end


  # call with a country_level instance
  def sample_geog_level_for_country_level(country_level)
    SampleGeogLevel.where(country_level_id: country_level.id, terrapop_sample_id: id).first
  end


  # call with the code given in GeogUnits - NAT, FLAD, etc...
  def sample_geog_level_for_code(lev_name)
    country_level = get_country_level(lev_name)
    if country_level.nil?
      nil
    else
      sample_geog_level_for_country_level(country_level)
    end
  end


  def short_country_name_long_year
    short_country_name + year.to_s
  end


  #########################################################
  # Generate/Retrieve Short Dataset Identifier
  #########################################################
  def dataset_identifier
    if sample_id.nil?
      # Terrapop Exclusive or NHGIS backed dataset
      dataset = short_country_name + (year.nil? ? (!(begin_year.nil? && end_year.nil?) && (begin_year.to_s[-2,2] + end_year.to_s[-2,2]) || '') : year.to_s[-2,2])
      if nhgis_dataset_id.nil?
        # Terrapop Exclusive dataset
        dataset += "_TP"
      else
        # NHGIS backed dataset
        dataset += "_NHGIS"
      end
      dataset
    else
      sample.name
    end
  end


  #########################################################
  # Privacy Controls for Small Samples
  #########################################################
  # Should only apply to samples with 100% sampling / complete count data
  def smooth_small_counts(threshold, new_value)
    sample.density == 100.0 or raise "Can only redact data from full count (100% sample)."
    # Get count variables attached to this sample
    vars_to_smooth = area_data_variables.joins(:measurement_type).where(measurement_types: {label: 'Count'}).pluck(:id).uniq
    data_to_update = AreaDataValue.all_data.where(area_data_variable_id: vars_to_smooth).where(['value <= ? and value >=0.0', threshold])
    data_to_update.update_all(value: new_value)
  end


  def redact_from_small_regions(region_size)
    sample.density == 100.0 or raise "Can only redact data from full count (100% sample)."
    region_count_var_ids = area_data_variables.joins(:measurement_type).where(mnemonic: :TOTPOP, measurement_types: {label: 'Count'}).pluck(:id).uniq
    region_counts = AreaDataValue.all_data.where(area_data_variable_id: region_count_var_ids)
    small_regions = region_counts.where(["value <= ?", region_size])
    small_region_ids = small_regions.all.map{ |r| r.geog_instance.id }
    values_to_redact = AreaDataValue.where(geog_instance_id: small_region_ids)
    values_to_redact.update_all(value: -1.0)
  end


  # NHGIS Ingest related
  def self.from_nhgis(nhgis_dataset, year = nil)
    #When provided a dataset from NHGIS, create a new UNSAVED terrapop sample setting five (ehem... four) attributes:
    #sample_id: integer,        ==>   nil
    #label: string,             ==>   Full country name with year, e.g. "Armenia 2000"; from NHGIS, this could be (from NHGIS): United States 1790 Census (NHGIS)
    #country_id: integer,       ==>   Country.find_by(short_name: :us).id
    #year: integer,             ==>   Note: might be nil and then set begin_year and end_year
    #short_country_name: string ==>   'US'  (notice, capital letters, versus the lower case in the above Country query)

    #generate a new instance of TerrapopSample
    terrapop_sample = self.new

    #associate the terrapop sample to the NHGIS dataset
    terrapop_sample.nhgis_dataset_id = nhgis_dataset.id

    #set the country code and the short label to the United States : NHGIS covers only the US (and PR)
    terrapop_sample.country_id = Country.find_by(short_name: :us).id
    terrapop_sample.short_country_name = "US"

    #set the label from the NHGIS dataset
    terrapop_sample.label = nhgis_dataset.terrapop_label

    #set the short_label from the NHGIS dataset
    terrapop_sample.short_label = nhgis_dataset.terrapop_short_label

    terrapop_sample.source_project = 'NHGIS'

    #set the year or years:  most NHGIS datasets cover only one year; a few others cover many, e.g. ACS 2009-2013
    #NOTE terrapop_years returns a label, so split on "-" -- if one exists at all
    terrapop_years = nhgis_dataset.terrapop_years       #prepare the list of years
    case terrapop_years.size
    when 2
      terrapop_sample.begin_year = terrapop_years.first
      terrapop_sample.end_year = terrapop_years.last
    when 1
      terrapop_sample.year = terrapop_years.first
    else
      raise "invalid value for terrapop_years: #{terrapop_years}" if year.nil?
      if year.is_a? Array and year.size == 2
        terrapop_sample.begin_year = year.first
        terrapop_sample.end_year   = year.last
      else
        terrapop_sample.year = year
      end
    end
    #do not save the terrapop sample here; save it elsewhere
    terrapop_sample
  end

  def tabulated_or_published
    unless is_tabulated?
      "published area-level data"
    else
      "tabulated from " + tabulated_sample_size[:value] + " microdata sample"
    end
  end


  def is_tabulated?
    !sample_id.nil?
  end


  def tabulated_sample_size
    if sample_detail_values.size > 0
      sample_detail_values_fields['sample_fraction']
    else
      {value: 'N/A', label: "Sample fraction"}
    end
  end

  def long_description

    snly = short_name_long_year

    snly[:short_name] + " " + country.full_name + " " + snly[:long_year].to_s + " " + tabulated_or_published

  end

  def short_name_long_year
    if sample_id.nil?
      country_code = short_country_name.downcase

      short_yr = if year.nil?
        begin_year.to_s[-2..-1] + end_year.to_s[-2..-1]
      else
        year
      end
      long_year = begin_year.to_s + "-" + end_year.to_s
      short_name = country_code + short_yr.to_s
    else
      long_year = year
      short_name = sample.name
    end

    {long_year: long_year, short_name: short_name}
  end

  def self.long_description(terrapop_samples)
    if terrapop_samples.count > 0
      str = []
      terrapop_samples.each do |tps|
        str << tps.long_description
      end
      str.join("\n")
    else
      "No Area-level Datasets"
    end
  end


  def country_name_year
    yr = if year.nil?
      begin_year.to_s[-2..-1] + end_year.to_s[-2..-1]
    else
      year
    end

    country.full_name + " " + yr.to_s
  end


  def country_name_long_year(pieces = false)
    yr = if year.nil?
      begin_year.to_s + "-" + end_year.to_s
    else
      year
    end

    unless pieces
      country.full_name + " " + yr.to_s
    else
      {country_name: country.full_name, long_year: yr.to_s}
    end
  end


  def long_citation
    str = []
    snly = short_name_long_year
    cnly = country_name_long_year(true)  # true => break the country and year into pieces; hash

    str << snly[:short_name] + " " + cnly[:country_name] + " " + snly[:long_year].to_s

    unless is_tabulated?

      str << "<citation for " + cnly[:country_name] + " " + snly[:long_year].to_s + " Census>.  Source data downloaded from <URL> on <date>"

    else

      str << "Tabulated from IPUMS-International microdata (https://international.ipums.org/international/)."
      str << "Original source data obtained by agreement from "

      unless sample_detail_values_fields.nil?
        if sample_detail_values_fields.has_key? "stats_office"
          unless sample_detail_values_fields["stats_office"].nil?
            if sample_detail_values_fields["stats_office"].has_key? :value
              str << sample_detail_values_fields["stats_office"][:value]
            end
          end
        end
      end

    end

    str.join("\n")
  end


  def self.long_citation(terrapop_samples)

    if terrapop_samples.count > 0
      str = []
      terrapop_samples.each do |tps|
        str << tps.long_citation
        str << ""
      end
      str << ""
      str.join("\n")
    else
      ""
    end

  end

  private


  def sample_detail_values_fields
    sample_detail_values.joins("JOIN sample_detail_fields sdf ON sample_detail_values.sample_detail_field_id = sdf.id").select("sdf.*, sample_detail_values.*").map{|o| {o.name => {label: o.label, value: o.value}}}.reduce Hash.new, :merge
  end


  def adjust_short_country_name_upcase
    short_country_name.upcase! if has_attribute?('short_country_name') && !short_country_name.nil?
  end


  def get_country_level(lev_name)
    GeogUnit.find_by_code(lev_name).country_levels.find_by(country_id: country_id)
  end


end
