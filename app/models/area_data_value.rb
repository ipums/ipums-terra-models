# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AreaDataValue < ActiveRecord::Base


  belongs_to :sample_level_area_data_variable
  belongs_to :area_data_variable
  belongs_to :geog_instance


  # returns a relation for all the area_data_variables for this sample_geog_level.
  # Call .all on the result to actually get the data.
  def self.by_area_data_variables_and_sample_geog_level(vars, level)
    selected_sample_area_data_variable_ids = vars.map{ |v| v.var_for_sample_level(level) }.flatten.compact.map{|var| var.id}
    all_data.where(sample_level_area_data_variable_id: selected_sample_area_data_variable_ids)
  end


  def self.all_data
    includes(:area_data_variable, :geog_instance).order("area_data_values.id")
  end


  def to_s
    value.nil? ? "<not set>" : "#{area_data_variable.mnemonic}: #{value}"
  end


  def mnemonic_sym
    area_data_variable.mnemonic.to_sym
  end

  def mnemonic
    construct_synthetic_mnemonic
  end

  def construct_synthetic_mnemonic
    # use the existing code on AreaDataVariable to generate the mnemonic
    area_data_variable.construct_synthetic_mnemonic(sample_level_area_data_variable.sample_geog_level)
  end


end
