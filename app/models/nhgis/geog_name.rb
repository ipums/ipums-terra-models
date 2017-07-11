# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

module Nhgis

  class GeogName < NhgisActiveRecord::Base

    belongs_to :geog_unit
    belongs_to :time_instance
    belongs_to :integ_geog_name
    has_many :geog_names,:foreign_key=>"parent_id"
    has_many :source_geog_instances
    has_many :shape_files

  end
end
