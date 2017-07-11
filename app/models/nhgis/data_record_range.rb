# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class DataRecordRange < NhgisActiveRecord::Base

    belongs_to :source_geog_instance
    belongs_to :data_file
  
    def to_range
     Range.new(line_number_min, line_number_max)
    end

    def to_range_as_indexes
     Range.new(line_number_min-1, line_number_max-1)
    end

    def self.available_data_record_ranges(data_file_id, source_geog_instance_ids)
      return [] if source_geog_instance_ids.count == 0
      where("source_geog_instance_id IN (#{source_geog_instance_ids.join(", ")}) AND data_file_id = #{data_file_id}").order("line_number_min")
    end

  end
end