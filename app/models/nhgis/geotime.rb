# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class Geotime < NhgisActiveRecord::Base

    belongs_to :geog_level
    belongs_to :time_instance
    has_many :data_groups
    has_many :shape_files

    def root
      root_geog_level = self.geog_level.root
      Geotime.find_by_geog_level_id_and_time_instance_id(root_geog_level, self.time_instance)
    end

    def geog_unit
      geog_level.geog_unit
    end

  end
  
end