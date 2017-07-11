# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterVariableClassifications < ActiveRecord::Migration

  def change
    create_table :raster_variable_classifications do |t|
      t.column    :raster_variable_id, :bigint
      t.timestamps
    end

    add_column :raster_variables, :raster_variable_classification_id, :bigint
    foreign_key :raster_variables, :raster_variable_classification_id
    
    add_index :raster_variables, :raster_variable_classification_id
    add_index :raster_variable_classifications, :raster_variable_id
    
    foreign_key :raster_variable_classifications, :raster_variable_id
    
    # add_index :rasters, :raster_variable_id
    
  end
end

# A RasterVariable that is mosaic'd has many RasterVariables
#
#
#
#
#
#
#
#