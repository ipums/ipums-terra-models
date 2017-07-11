# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

module Nhgis

  class GeogUnit < NhgisActiveRecord::Base

    has_many :integ_geog_names
    has_many :geog_names
    has_many :integ_geog_levels
    has_many :geog_levels
    has_many :geog_units, :foreign_key=>"parent_id"

  end
end