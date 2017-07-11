# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddStatsToRasterDatasets < ActiveRecord::Migration

  def change
    
    add_column :raster_datasets, :max,    :decimal, precision: 512, scale: 8
    add_column :raster_datasets, :mean,   :decimal, precision: 512, scale: 8
    add_column :raster_datasets, :min,    :decimal, precision: 512, scale: 8
    add_column :raster_datasets, :nodata, :decimal, precision: 512, scale: 8
    add_column :raster_datasets, :stddev, :decimal, precision: 512, scale: 8
    
  end
end
