# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

module Nhgis

  class GeogLevelCollection

    attr_accessor :geogs_with_boundary_files
    attr_accessor :preselected_geog_levels
    attr_accessor :geog_level_groups

    def initialize(preselected_geog_levels, available_geog_levels)
      @preselected_geog_levels = GeogLevel.find_all_by_istads_id(preselected_geog_levels).sort{|a,b| a.istads_seq <=> b.istads_seq}
      @geog_level_groups = GeogLevelGroup.all_geog_level_groups_using(preselected_geog_levels, available_geog_levels)
      @geogs_with_boundary_files = GeogLevel.find_geog_levels_having_shapefiles.map{|obj|obj.istads_id}
    end

  end
end