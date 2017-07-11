# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddRasterBandToRasterDatasetModel < ActiveRecord::Migration

  def change
    add_column     :raster_datasets, :raster_band_index, :bigint, default: -1, null: false
    remove_column  :raster_categories, :raster_band_index
    add_index      :raster_datasets, :raster_band_index
  end
end
