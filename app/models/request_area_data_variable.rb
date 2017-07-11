# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RequestAreaDataVariable < ActiveRecord::Base

  belongs_to :extract_request
  belongs_to :area_data_variable

  # This should be a belongs_to
  attr_accessor :sample_geog_level


  def mnemonic
    mnem = sample_geog_level ? area_data_variable.construct_synthetic_mnemonic(sample_geog_level)   : area_data_variable.mnemonic
    
    adrvml = AreaDataRasterVariableMnemonicLookup.where(composite_mnemonic: mnem).first
    
    if adrvml.nil?
      
      geography_name = SampleGeogLevel.geography_name(sample_geog_level)
      
      desc = area_data_variable.label + " (" + area_data_variable.measurement_type.label + ")"
      
      AreaDataRasterVariableMnemonicLookup.create!(composite_mnemonic: mnem, mnemonic: area_data_variable.mnemonic, geog_level: geography_name, dataset_label: (sample_geog_level.nil? ? "" : sample_geog_level.terrapop_sample.short_name_long_year[:short_name]), description: desc)
    end
    
    
    mnem
  end


  def categories
    area_data_variable.categories
  end


  def len
    area_data_variable.len
  end


  def implied_decimal_places
    area_data_variable.implied_decimal_places
  end


  def label
    area_data_variable.label
  end


  def data_type
    area_data_variable.data_type
  end


  def measurement_type
    area_data_variable.measurement_type
  end

end
