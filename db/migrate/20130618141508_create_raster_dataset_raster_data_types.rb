# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterDatasetRasterDataTypes < ActiveRecord::Migration

  def change
    
    create_table :raster_dataset_raster_data_types do |t|
      t.column    :raster_dataset_id,   :bigint
      t.column    :raster_data_type_id, :bigint
      t.timestamps
    end

    add_index :raster_dataset_raster_data_types, :raster_dataset_id
    add_index :raster_dataset_raster_data_types, :raster_data_type_id
    
    foreign_key :raster_dataset_raster_data_types, :raster_dataset_id
    foreign_key :raster_dataset_raster_data_types, :raster_data_type_id
    
  end
end
