# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RasterDatasetUnit < ActiveRecord::Base

  has_many :raster_dataset_raster_dataset_units
  has_many :raster_datasets, :through => :raster_dataset_raster_dataset_units
end
