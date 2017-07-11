# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class DataFile < NhgisActiveRecord::Base

    belongs_to :data_group
    belongs_to :breakdown_combo
    belongs_to :data_file_type
    has_many :data_record_ranges

    def geog_level
      data_group.geog_level
    end

    def geog_unit
      data_group.geog_unit
    end

    def datatime_label
      datatime_time_instance.label
    end

    def geogtime_instance
      data_group.geotime.time_instance
    end

    def geogtime_label
      geogtime_instance.label
    end

    def geog_time_instance_id
      data_group.geog_time_instance_id
    end

    def datatime_time_instance
      data_group.datatime
    end

    def gisjoin_geog_vars
      data_group.geog_vars_for_gis_join
    end
    
  end
end