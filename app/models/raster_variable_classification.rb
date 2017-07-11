# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RasterVariableClassification < ActiveRecord::Base

  belongs_to :raster_variable
  belongs_to :mosaic_raster_variable, class_name: 'RasterVariable', foreign_key: 'id'
  belongs_to :classification_raster_variable, class_name: 'RasterVariable', foreign_key: "mosaic_raster_variable_id"
end
