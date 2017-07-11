# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class SampleGeogLevel < ActiveRecord::Base

  include ActionView::Helpers::NumberHelper

  has_many :geog_instances
  has_many :sample_level_area_data_variables
  has_many :request_raster_variables
  has_many :request_area_data_variables
  has_many :area_data_rasters
  has_many :area_data_variables, through: :sample_level_area_data_variables

  belongs_to :country_level
  belongs_to :terrapop_sample
  # geolinking_variable is the id of the variable to link with when attaching area-level characteristics to microdata extracts.
  belongs_to :geolink_variable, class_name: 'Variable', foreign_key: 'geolink_variable_id'


  def api_attributes
    "TODO"
  end


  def geog_unit
    country_level.geog_unit
  end


  def map
    Map.where(country_level_id: country_level_id, terrapop_sample_id: terrapop_sample_id).first
  end


  def self.long_description(sample_geog_levels)
    if sample_geog_levels.count > 0
      level_order = ['NAT', 'HFLAD', 'FLAD', 'HSLAD', 'SLAD']
      levels = {}
      str = []
      sample_geog_levels.each do |sgl|
        levels[sgl.country_level.geog_unit.code] = [] unless levels.has_key?(sgl.country_level.geog_unit.code)
        levels[sgl.country_level.geog_unit.code] << sgl.long_description
      end
      levels.each{ |key, lvls| levels[key] = lvls.sort }
      level_order.each do |lvl|
        if levels.has_key? lvl
          str << GeogUnit.where(code: lvl).first.label + " (" + lvl + ")"
          levels[lvl].each{ |lvl_txt| str << "  " + lvl_txt }
        end
      end
      str.join("\n")
    else
      "No Geographic Levels"
    end
  end


  def long_description
    terrapop_sample.country_name_long_year + ": " + (country_level.geog_unit.code == "NAT" ? "National" : country_level.label)
  end

  # Use the geolinking variable from the microdata to help generate the
  # AreaVariable stubs that are the geography instances
  # on each row of the area data tables. We need four:
  # 1. geog level label (State, county, etc.)
  # 2. geog level code: (STATEBR, STATEUS, etc.)
  # 3. geog instance label ("Alabama","Hennepin", etc.)
  # 4. geog instance code (25,28, whatever codes are used for categories of 3
  def variables_for_area_data_extracts
    geog_instance_variable = "GEOG_CODE"
    geog_instance_variable = geolink_variable.mnemonic || "GEOG_CODE" unless geolink_variable.nil?
    geog_instance_label = "#{geog_instance_variable}_LABEL"

    adrvml_code = AreaDataRasterVariableMnemonicLookup.where(["LOWER(composite_mnemonic) = ?", geog_instance_variable.downcase]).first

    if adrvml_code.nil?
      adrvml_code = AreaDataRasterVariableMnemonicLookup.new
      adrvml_code.description = 'GIS match code'

      unless geolink_variable.nil?
        adrvml_code.description += ' [' + geolink_variable.label + ']'
      end

      adrvml_code.composite_mnemonic = geog_instance_variable
      adrvml_code.mnemonic = geog_instance_variable

      adrvml_code.save
    end

    adrvml_label = AreaDataRasterVariableMnemonicLookup.where(["LOWER(composite_mnemonic) = ?", geog_instance_label.downcase]).first

    if adrvml_label.nil?
      adrvml_label = AreaDataRasterVariableMnemonicLookup.new
      adrvml_label.description = 'Name of geographic instances'
      adrvml_label.composite_mnemonic = geog_instance_label
      adrvml_label.mnemonic = geog_instance_label
      adrvml_label.save
    end

    [
      # ExtractVariableStub.new(:mnemonic => "Geog_level_label",     :label=>"Geog level label",    :len => 32, :data_type => "alphabetical"),
      # ExtractVariableStub.new(:mnemonic => "Geog_level_code",      :label=>"Geog level code",     :len => 10, :data_type => "alphabetical"),
      ExtractVariableStub.new(mnemonic: geog_instance_label,    label: "Geog instance label", len: 32, data_type: "alphabetical"),
      ExtractVariableStub.new(mnemonic: geog_instance_variable, label: "Geog instance code",  len: 10, data_type: "integer")
    ]
  end

  #from_nhgis_terrapop_sample presumes that the terrapop sample is associated to an NHGIS dataset; if it is not, return an empty set
  # the number of sample geog levels returned depends upon the number of country levels associated to the terrapop
  # sample; e.g. 3: one for US-NAT (United States), one for US-HFLAD (states), and one for US-HSLAD (counties)
  def self.from_nhgis_terrapop_sample(nhgis_terrapop_sample)
    #return an empty list if the terrapop sample is not linked to an NHGIS dataset
    return [] if nhgis_terrapop_sample.nhgis_dataset_id.nil?
    #TODO create a relation in Terrapop Sample?  too drastic
    nhgis_dataset = Nhgis::Dataset.where(id: nhgis_terrapop_sample.nhgis_dataset_id).first
    return [] if nhgis_dataset.nil?
    #identify the country for the TerrapopSample
    country = nhgis_terrapop_sample.country
    raise "expecting the terrapop sample label to include the name of the country '#{country.full_name}'" unless nhgis_terrapop_sample.label.include? country.full_name
    # only those NHGIS datasets having nation-, state-, or county-level data are ever to be considered for terrapop samples.  There are some NHGIS datasets that
    # participate in time series tables but do not have any nation-, state-, or county-level data.  Since Terrapop only has NAT, *FLAD, *SLAD, those datasets are
    # to be excluded.
    # conversion from NHGIS geog levels/geog units to Terrapop geog units
    nhgis_gl_to_terrapop_gu = {"nation" => "NAT", "state" => "FLAD", "county" => "SLAD"}
    valid_geog_units = nhgis_dataset.data_groups.reject{ |dg| dg.relative_pathname.nil? }.map{ |dg| dg.relative_pathname.nil? ? nil : nhgis_gl_to_terrapop_gu[dg.geog_level.istads_id] }.reject{ |gl_istads_id| gl_istads_id.nil? }
    geog_unit_ids = GeogUnit.where(code: valid_geog_units).pluck(:id)
    #identify all of the country levels for the terrapop sample's country
    country_levels = CountryLevel.where(country_id: nhgis_terrapop_sample.country_id, geog_unit_id: geog_unit_ids).all
    country_levels.map do |country_level|
      sgl = SampleGeogLevel.new
      sgl.country_level = country_level
      sgl.terrapop_sample = nhgis_terrapop_sample
      gu = country_level.geog_unit
      sgl.internal_code = "#{country.short_name}#{nhgis_dataset.code}_#{gu.code}"
      harmonized = ["HFLAD", "HSLAD"].include?(gu.code) ? " (Harmonized)" : "" #National country level need not be harmonized; only states and counties are harmonized
      country_level_label = gu.code == "NAT" ? gu.label : country_level.label #use the geog unit label... which is expected to be 'National' (whereas United States represents extent)
      sgl.label = nhgis_terrapop_sample.label.gsub(country.full_name, "#{country.full_name}: #{country_level_label}#{harmonized},")
      sgl #do not set values for id, created_at, updated_at, code, and geolink_variable
    end
  end


  def self.geography_name(sample_geog_level)
    if sample_geog_level.nil?
      ""
    else
      if sample_geog_level.geolink_variable.nil?
        sample_geog_level.terrapop_sample.short_country_name.upcase + "_" + sample_geog_level.country_level.geog_unit.code.upcase
      else
        sample_geog_level.geolink_variable.mnemonic
      end
    end
  end


  def geography_instance_areas
    boundary_ids = geog_instances.map{|g| g.boundaries.first.id }
    sql = "SELECT id, ST_Area(geog) AS area FROM boundaries WHERE id IN (?)"
    clean_sql = SampleGeogLevel.send(:sanitize_sql_array, [sql, boundary_ids])
    SampleGeogLevel.connection.execute(clean_sql)
  end


  def statistics
    [unit_populations, unit_areas, codes_and_labels].compact
  end

  def variable_available?(area_data_variable_id)
    true unless self.area_data_variables.where(id: area_data_variable_id).empty?
  end


  private


  def unit_populations
    begin
      ["NAT", "HFLAD", "HSLAD"].include?(geog_unit.code) ? nil : {
        label: "Unit Populations",
        values: [
          "Min: #{number_with_delimiter(geog_instances.joins(:area_data_values).minimum("area_data_values.value").try(:to_i)) || 'N/A'}",
          "Max: #{number_with_delimiter(geog_instances.joins(:area_data_values).maximum("area_data_values.value").try(:to_i)) || 'N/A'}",
          "Mean: #{number_with_delimiter(geog_instances.joins(:area_data_values).average("area_data_values.value").try(:to_i)) || 'N/A'}",
          "Std. Dev.: #{number_with_delimiter(geog_instances.joins(:area_data_values).pluck("STDDEV(area_data_values.value)").first.try(:to_i)) || 'N/A'}"
        ]
      }
    rescue Exception
      nil
    end
  end


  def unit_areas
    min = begin
      "Min: #{number_with_delimiter(geog_instances.joins(:boundaries).minimum("ST_Area(geog)").try(:to_i)/1000000)}"
    rescue Exception
      "Min: N/A"
    end
    max = begin
      "Max: #{number_with_delimiter(geog_instances.joins(:boundaries).maximum("ST_Area(geog)").try(:to_i)/1000000)}"
    rescue Exception
      "Max: N/A"
    end
    avg = begin
      "Mean: #{number_with_delimiter(geog_instances.joins(:boundaries).average("ST_Area(geog)").try(:to_i)/1000000)}"
    rescue Exception
      "Mean: N/A"
    end
    std = begin
      "Std. Dev.: #{number_with_delimiter(geog_instances.joins(:boundaries).pluck("STDDEV(ST_Area(geog))").first.try(:to_i)/1000000)}"
    rescue Exception
      "Std. Dev.: N/A"
    end
    {
      label: "Unit Areas (sq. km)",
      values: [min, max, avg, std]
    }
  end


  def codes_and_labels
    begin
      {
        label: "Codes and Labels",
        values: geog_instances.map{ |geog_instance| "#{geog_instance.str_code} #{geog_instance.label}" }
      }
    rescue Exception
      nil
    end
  end


end
