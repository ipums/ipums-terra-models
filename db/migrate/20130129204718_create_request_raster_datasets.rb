# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRequestRasterDatasets < ActiveRecord::Migration

  def change
    create_table :request_raster_datasets do |t|
      t.column :raster_dataset_id,  :bigint, :null => false
      t.column :extract_request_id, :bigint, :null => false
      t.timestamps
    end
    
    foreign_key(:request_raster_datasets, :raster_dataset_id)
    foreign_key(:request_raster_datasets, :extract_request_id)
    
  end
end
