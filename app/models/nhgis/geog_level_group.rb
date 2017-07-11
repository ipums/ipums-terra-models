# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class GeogLevelGroup < NhgisActiveRecord::Base
    has_many :geog_level_geog_level_groups
    has_many :geog_levels, :through=>:geog_level_geog_level_groups

    def initialize
      @available_geog_levels = nil
      @available_geog_unit_hash = nil
      @available_geog_units = nil
      @major_count = 0
      @all_count = 0
    end

    def self.all_geog_level_groups_using(preselected, available)
      #groups = find(:all, :order => "istads_seq")
      groups = order("istads_seq")
      groups.each{|grp| grp.preselect_disable_using(preselected, available)}
      groups
    end

    def grab_geog_levels_for(geog_unit_id, geog_type)
      hash_for_gu = grab_geog_unit_hash[geog_unit_id]
      return [] unless hash_for_gu

      hash = hash_for_gu[:geog_level]
      return [] unless hash

      hash[geog_type] || []
    end

    def has_major_geog_levels_only
      initialize_geog_level_group if @all_count == 0
      @major_count == @all_count
    end

    def grab_available_geog_units
      initialize_geog_level_group unless @available_geog_units
      @available_geog_units
    end

    def preselect_disable_using(preselected, available)
      gl_list = grab_available_geog_levels
      unavailable = GeogLevel.exclude_from(gl_list, available)
      gl_list.each{|gl|
        gl.preselect_using(preselected)
        gl.disable_using(unavailable)
      }
    end

    private

    def grab_available_geog_levels
      initialize_geog_level_group unless @available_geog_levels
      @available_geog_levels
    end

    def grab_geog_unit_hash
      initialize_geog_level_group unless @available_geog_unit_hash
      @available_geog_unit_hash
    end

    def initialize_geog_level_group
      @available_geog_unit_hash = {}
      @available_geog_units = []
      @available_geog_levels = GeogLevel.available_geog_levels_for_geog_level_group(self.id)
      @major_count = 0
      @all_count = 0

      gl_id_list = @available_geog_levels.map{|gl|gl.id}
      GeogUnit.geog_units_for_geog_level_ids(gl_id_list).each{|gu|
        @available_geog_unit_hash[gu.id] = {:geog_level => {"all" => [], "major" => []}}
        @available_geog_units << gu unless @available_geog_units.include? gu
      }

      @available_geog_levels.each{|gl|
        @available_geog_unit_hash[gl.geog_unit_id][:geog_level]["all"] << gl
        @all_count += 1
        if gl.is_major?
          @available_geog_unit_hash[gl.geog_unit_id][:geog_level]["major"] << gl
          @major_count += 1
        end
      }
    end

  end
end