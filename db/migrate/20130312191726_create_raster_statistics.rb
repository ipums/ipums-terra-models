# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterStatistics < ActiveRecord::Migration

  def change
    
    create_table :raster_statistics do |t|
      t.column      :geog_instance_id,   :bigint
      t.column      :raster_variable_id, :bigint
      t.column      :mean,               :decimal, :precision => 64, :scale => 10
      t.column      :stddev,             :decimal, :precision => 64, :scale => 10
      t.column      :cellcount,          :bigint
      t.column      :summation,          :decimal, :precision => 64, :scale => 10
      t.column      :min,                :decimal, :precision => 64, :scale => 10
      t.column      :max,                :decimal, :precision => 64, :scale => 10
      t.timestamps
    end
    
    add_index   :raster_statistics, :geog_instance_id
    add_index   :raster_statistics, :raster_variable_id
    
    foreign_key :raster_statistics, :geog_instance_id
    foreign_key :raster_statistics, :raster_variable_id
    
  end
end
