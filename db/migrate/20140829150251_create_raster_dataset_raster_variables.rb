# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterDatasetRasterVariables < ActiveRecord::Migration

  def change
    
    create_table :raster_dataset_raster_variables do |t|
      t.column     :raster_variable_id,  :bigint, null: false
      t.column     :raster_dataset_id,   :bigint, null: false
      t.timestamps
    end
    
    add_index :raster_dataset_raster_variables, :raster_variable_id
    add_index :raster_dataset_raster_variables, :raster_dataset_id
    
    foreign_key :raster_dataset_raster_variables, :raster_variable_id
    foreign_key :raster_dataset_raster_variables, :raster_dataset_id
    
  end
end
