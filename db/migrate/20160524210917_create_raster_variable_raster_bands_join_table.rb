# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterVariableRasterBandsJoinTable < ActiveRecord::Migration


  def up
    create_table :raster_variable_raster_bands do |t|
      t.column :raster_variable_id, :bigint, null: false
      t.column :raster_band_id, :bigint, null: false
      t.timestamps
    end

    add_index :raster_variable_raster_bands, :raster_variable_id
    add_index :raster_variable_raster_bands, :raster_band_id

    foreign_key :raster_variable_raster_bands, :raster_variable_id
    foreign_key :raster_variable_raster_bands, :raster_band_id
  end

  def down
    drop_table :raster_variable_raster_bands
  end

end
