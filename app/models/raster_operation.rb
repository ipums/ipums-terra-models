# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RasterOperation < ActiveRecord::Base


  belongs_to :raster_data_type

  belongs_to :parent, :class_name => "RasterOperation", :foreign_key => "parent_id"
  has_many :children, :class_name => "RasterOperation", :foreign_key => "parent_id"

  alias_attribute :data_type_id, :raster_data_type_id

end
