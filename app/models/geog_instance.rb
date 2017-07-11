# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class GeogInstance < ActiveRecord::Base


  has_many :boundaries
  has_many :raster_categories
  has_many :raster_statistics
  has_many :raster_category_statistics
  has_many :area_data_statistics
  has_many :area_data_values

  belongs_to :sample_geog_level
  belongs_to :terrapop_sample

  belongs_to :parent, :class_name => "GeogInstance", :foreign_key => "parent_id"
  has_many :children, :class_name => "GeogInstance", :foreign_key => "parent_id"

  def to_s
    label.nil? ? "<not set>" : label + "(#{code})"
  end
end
