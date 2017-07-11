# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class TimeSeriesTableTopic < NhgisActiveRecord::Base
    self.table_name = "topics_x_time_series_tables"

    belongs_to :time_series_table
    belongs_to :topic
  end
end