# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddSummaryToRasterVariable < ActiveRecord::Migration

  def change
    add_column :raster_variables, :mean,                :decimal, :precision => 64, :scale => 10
    add_column :raster_variables, :stddev,              :decimal, :precision => 64, :scale => 10
    add_column :raster_variables, :summation,           :decimal, :precision => 64, :scale => 10
    add_column :raster_variables, :cellcount,           :bigint
    add_column :raster_variables, :cellcount_with_data, :bigint
    add_column :raster_variables, :min,                 :decimal, :precision => 64, :scale => 10
    add_column :raster_variables, :max,                 :decimal, :precision => 64, :scale => 10
  end
end
