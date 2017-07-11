# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class WidenNumericFieldsOnRasterVariable < ActiveRecord::Migration

  def change
    
    change_column :raster_variables, :max,    :decimal, precision: 512, scale: 8
    change_column :raster_variables, :mean,   :decimal, precision: 512, scale: 8
    change_column :raster_variables, :min,    :decimal, precision: 512, scale: 8
    change_column :raster_variables, :nodata, :decimal, precision: 512, scale: 8
    change_column :raster_variables, :stddev, :decimal, precision: 512, scale: 8
    
  end
end
