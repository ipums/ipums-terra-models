# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddNorthSouthEastWestColumnsToRasterDataset < ActiveRecord::Migration

  def change
    add_column :raster_datasets, :north_extent, :decimal, :precision => 64, :scale => 10
    add_column :raster_datasets, :south_extent, :decimal, :precision => 64, :scale => 10
    add_column :raster_datasets, :east_extent,  :decimal, :precision => 64, :scale => 10
    add_column :raster_datasets, :west_extent,  :decimal, :precision => 64, :scale => 10
  end
end
