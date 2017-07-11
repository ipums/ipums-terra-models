# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddRasterTableNameRefToBands < ActiveRecord::Migration


  def up
    add_column :raster_bands, :raster_table_name_id, :integer
    add_index :raster_bands, :raster_table_name_id
    foreign_key_raw :raster_bands, :raster_table_name_id, :raster_table_names, :id
  end

  def down
    remove_column :raster_bands, :raster_table_name_id, :integer
  end

end
