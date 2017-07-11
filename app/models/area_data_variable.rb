# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AreaDataVariable < ActiveRecord::Base


  has_many :area_data_values
  has_many :sample_level_area_data_variables
  has_many :sample_geog_levels, through: :sample_level_area_data_variables
  has_many :area_data_variable_constructions
  has_many :variables, through: :area_data_variable_constructions
  has_many :terrapop_samples, -> { uniq }, through: :sample_level_area_data_variables
  has_many :area_data_statistics
  has_many :area_data_rasters

  has_and_belongs_to_many :topics

  belongs_to :area_data_table
  belongs_to :measurement_type

  scope :alphabetical, -> { order(mnemonic: :asc) }

  alias_attribute :dataset_ids, :terrapop_sample_ids
  alias_attribute :width, :len


  # given a sample_geog_level, return the sample_level_area_data_variable for this var for that sample_geog_level.
  # there should only be one.
  def var_for_sample_level(sample_geog_level)
    sample_level_area_data_variables.belonging_to_level(sample_geog_level).first
  end


  # return the mnemonic for this variable as a symbol.
  def mnemonic_sym
    mnemonic.to_sym
  end


  # Need this to be accessible before retrieving area_data_values, since the
  # synthetic_mnemonic is needed at request time but the data isn't known yet.
  def construct_synthetic_mnemonic_sym(sample_geog_level)
    construct_synthetic_mnemonic(sample_geog_level).to_sym
  end


  def construct_synthetic_mnemonic(sample_geog_level)
    mnm = "#{mnemonic}_"
    mnm +=
      if sample_geog_level.geolink_variable.nil?
        "#{sample_geog_level.terrapop_sample.short_country_name.upcase}_#{sample_geog_level.country_level.geog_unit.code.upcase}"
      else
        "#{sample_geog_level.geolink_variable.mnemonic}"
      end
    mnm += "_#{sample_geog_level.terrapop_sample.dataset_identifier}"
    mnm.upcase
  end


  def implied_decimal_places
    case data_type
      when 'integer'
        0
      when 'decimal'
        3
    end
  end


  def data_type
    case measurement_type.label
      when 'Count', 'Modal'
        'integer'
      when 'Mean', 'Median', 'Percentage', 'Area'
        'decimal'
      else
        'integer'
    end
  end


  def len
    10
  end


  def categories
    []
  end


  def availability_by_country_and_long_year
    terrapop_samples.map{ |terrapop_sample| terrapop_sample.short_country_name_long_year }.uniq
  end


  def availability_by_country
    store = {}
    sample_level_area_data_variables.includes(terrapop_sample: :country).find_each do |sladv|
      unless sladv.terrapop_sample.country.nil?
        country_code = sladv.terrapop_sample.country.full_name
        store[country_code] ||= []
        store[country_code] << sladv.terrapop_sample.year
      end
    end
    store = Hash[store.sort]
    _availability_by_country = {}
    store.each { |key, val| _availability_by_country[key] = val.uniq.sort }
    _availability_by_country
  end


  def to_s
    mnemonic.nil? ? "<not set>" : mnemonic
  end


  def category_id
    area_data_table.category_id
  end


  def long_description
    mnemonic + " " + label + " (" + measurement_type.label + ")"
  end


  def self.long_description(area_data_variables)
    if area_data_variables.count > 0
      str = []
      area_data_variables.each do |adv|
        str << adv.long_description
      end
      str.join("\n")
    else
      "No Area-level Variables"
    end
  end

end
