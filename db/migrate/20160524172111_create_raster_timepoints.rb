# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterTimepoints < ActiveRecord::Migration


  def up
    create_table :raster_timepoints do |t|
      t.integer :raster_dataset_id
      t.string :mnemonic
      t.string :label
      t.timestamps
    end
    add_index :raster_timepoints, :raster_dataset_id
    foreign_key_raw :raster_timepoints, :raster_dataset_id, :raster_datasets, :id
  end


  def down
    drop_table :raster_timepoints
  end

end
