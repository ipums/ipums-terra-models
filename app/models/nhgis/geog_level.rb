# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class GeogLevel < NhgisActiveRecord::Base

    has_many :geotimes
    belongs_to :geog_unit
  
    has_many :geog_var_geog_levels
    has_many :geog_vars,:through=>:geog_var_geog_levels

    scope :nation_state_county, -> {where(["label IN ('county', 'state', 'nation')"])}
    
  end
end