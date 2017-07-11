# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateMapUnitRasterDatasets < ActiveRecord::Migration

  def change
    
    create_table :map_unit_raster_datasets do |t|
      t.column     :map_unit_id, :bigint, null: false
      t.column     :raster_dataset_id, :bigint, null: false
      t.timestamps
    end
    
    add_index   :map_unit_raster_datasets, :map_unit_id
    add_index   :map_unit_raster_datasets, :raster_dataset_id
    
    foreign_key :map_unit_raster_datasets, :map_unit_id
    foreign_key :map_unit_raster_datasets, :raster_dataset_id
    
  end
end
