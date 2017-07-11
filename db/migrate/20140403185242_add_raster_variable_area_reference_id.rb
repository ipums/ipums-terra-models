# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddRasterVariableAreaReferenceId < ActiveRecord::Migration

  def up
    add_column :raster_variables, :area_reference_id, :bigint
    add_index :raster_variables, :area_reference_id
    
    foreign_key_raw :raster_variables, :area_reference_id, :raster_variables, :id
    
  end

  def down
  end
end
