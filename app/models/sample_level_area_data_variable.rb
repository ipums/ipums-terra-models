# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class SampleLevelAreaDataVariable < ActiveRecord::Base


  belongs_to :area_data_variable
  belongs_to :terrapop_sample
  belongs_to :sample_geog_level
  has_many :area_data_values

  # get all the SampleLevelAggVars that are associated with a given sample_geog_level
  scope :belonging_to_level, lambda {|geog_level| where(:sample_geog_level_id => geog_level.id) }

  has_and_belongs_to_many :variables, :join_table => :sample_level_area_variable_constructions

end
