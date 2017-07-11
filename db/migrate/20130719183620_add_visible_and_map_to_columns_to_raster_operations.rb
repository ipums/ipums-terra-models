# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddVisibleAndMapToColumnsToRasterOperations < ActiveRecord::Migration

  def change
    
    add_column :raster_operations, :visible, :bool, :default => true
    add_column :raster_operations, :parent_id,  :bigint
    
    foreign_key_raw(:raster_operations, :parent_id, :raster_operations, :id)
    
    add_index :raster_operations, :parent_id
    
    
  end
end
