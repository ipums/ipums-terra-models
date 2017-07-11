# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class SampleVariable < ActiveRecord::Base

  
  has_and_belongs_to_many :sample_level_area_data_variables, :join_table => :sample_level_area_variable_constructions
  belongs_to :variable
  belongs_to :sample
  belongs_to :universe

  has_many :variable_sources, :foreign_key => :makes
  has_many :sample_variables, :through     => :variable_sources, :source => :is_made_of

end
