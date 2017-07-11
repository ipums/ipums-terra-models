# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AlterAreaDataRasterIndexes < ActiveRecord::Migration

  def change
    remove_index  :area_data_rasters, name: :area_data_rasters_uniq_index
    
    add_column :area_data_rasters, :geog_instance_id, :bigint
    
    add_index :area_data_rasters, [:sample_geog_level_id, :raster_variable_id, :area_data_variable_id, :geog_instance_id, :raster_size], unique: true, name: :area_data_rasters_uniq_index
    
    foreign_key :area_data_rasters, :geog_instance_id
    
  end
end
