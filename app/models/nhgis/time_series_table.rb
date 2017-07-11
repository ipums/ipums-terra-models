# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class TimeSeriesTable < NhgisActiveRecord::Base

    has_many :time_series_table_x_time_series
    has_many :time_series, through: :time_series_table_x_time_series

    has_many :time_series_table_time_instances
    has_many :time_instances, through: :time_series_table_time_instances
    
  end
  
end