# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RasterBand < ActiveRecord::Base

  belongs_to :raster_table_name
  has_many :raster_variable_raster_bands
  has_many :raster_variables, through: :raster_variable_raster_bands
  has_many :raster_visualizations
  has_many :raster_histograms
end
