# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterCategoryStatistics < ActiveRecord::Migration

  def change
    
    create_table :raster_category_statistics do |t|
      t.column      :geog_instance_id,   :bigint
      t.column      :raster_variable_id, :bigint
      t.column      :raster_category_id, :bigint
      t.column      :code,               :bigint
      t.column      :total_count,        :bigint
      t.timestamps
    end
    
    add_index :raster_category_statistics, :geog_instance_id
    add_index :raster_category_statistics, :raster_variable_id
    add_index :raster_category_statistics, :raster_category_id
    
    foreign_key :raster_category_statistics, :geog_instance_id
    foreign_key :raster_category_statistics, :raster_variable_id
    foreign_key :raster_category_statistics, :raster_category_id
    
  end
end
