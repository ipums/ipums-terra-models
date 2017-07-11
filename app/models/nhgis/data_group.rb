# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class DataGroup < NhgisActiveRecord::Base

    belongs_to :geotime
    belongs_to :dataset
    belongs_to :datatime, :class_name => 'TimeInstance'
    has_many :data_files
    has_many :source_geog_instances

    def geog_vars
      geotime.geog_level.geog_vars & dataset.geog_vars
    end

    def geog_level
      geotime.geog_level
    end

    def geog_unit
      geotime.geog_unit
    end

    def geog_time_instance_id
      geotime.time_instance_id
    end

    def parent_geog_vars(geog_level)
      parent_level = geog_level.parent
      parent_level ? parent_geog_vars(parent_level) + geog_level.geog_vars : geog_level.geog_vars
    end

    def geog_vars_for_gis_join
      parent_geog_vars(geotime.geog_level) & dataset.geog_vars
    end

    def available_integ_geog_names
      self.root.source_geog_instances.map{|sgi| sgi.geog_name.integ_geog_name}.uniq
    end
  
    def data_files_for_breakdown_values(breakdown_values)
      available_data_files(breakdown_values.map{|bv| bv.istads_id})
    end
  

    def available_data_files(breakdown_value_istads_ids)
      return DataFile.find_all_for(self.id, breakdown_value_istads_ids)
    end

    def source_geog_instances_for(integ_geog_names)
      root.source_geog_instances.select{|sgi| integ_geog_names.include? sgi.geog_name.integ_geog_name}.uniq
    end

    def self.find_all_for(dataset_id, geog_level_id, datatime_instance_id, geogtime_instance_id)
      #answer the data groups for the specified dataset, and geog levels
      #  typically, there will be just one data group per dataset/geog level.
      #  however, expect more than one data group whenever the dataset has multiple time instances

      return [] if dataset_id.nil?        #the dataset id must be provided to get anything back!!

      gt_join_clause = ""
      gl_where_clause = ""
      geog_ti_where_clause = ""
      if !geog_level_id.nil? || !geogtime_instance_id.nil?
        gt_join_clause = "JOIN geotimes gt ON gt.id = dg.geotime_id"
        gl_where_clause = "AND gt.geog_level_id = #{geog_level_id}" if !geog_level_id.nil?
        geog_ti_where_clause = "AND gt.time_instance_id = #{geogtime_instance_id}" if !geogtime_instance_id.nil?
      end

      data_ti_where_clause = ""
      data_ti_where_clause = "AND dg.datatime_id = #{datatime_instance_id}" unless datatime_instance_id.nil?

      sql =<<-EOS
        SELECT DISTINCT dg.* FROM data_groups dg #{gt_join_clause}
        WHERE dg.dataset_id = #{dataset_id} #{gl_where_clause} #{geog_ti_where_clause} #{data_ti_where_clause}
        ORDER BY dg.istads_seq
      EOS
      find_by_sql(sql)
    end

    def self.find_all_available_for(dataset_id, geog_level_ids, data_time_instance_ids)
      #answer the data groups for the specified dataset, and geog levels
      #  typically, there will be just one data group per dataset/geog level.
      #  however, expect more than one data group whenever the dataset has multiple time instances

      gl_join_clause = ""
      gl_where_clause = ""
      ti_where_clause = ""

      unless geog_level_ids.empty?
        gl_join_clause = "JOIN geotimes gt ON gt.id = dg.geotime_id"
        gl_where_clause = "AND gt.geog_level_id in (#{geog_level_ids.join(", ")})"
      end
      unless data_time_instance_ids.empty?
        ti_where_clause = "AND dg.datatime_id in (#{data_time_instance_ids.join(", ")})"
      end
      sql =<<-EOS
        SELECT DISTINCT dg.* FROM data_groups dg #{gl_join_clause}
        WHERE dg.relative_pathname IS NOT NULL AND 
        dg.dataset_id = #{dataset_id} #{gl_where_clause} #{ti_where_clause}
        ORDER BY dg.istads_seq
      EOS
      find_by_sql(sql)
    end

    def extract_output_name(prefix)
      #
      #  specify data group's portion of the 'base filename' to which the extract engine should assign selected
      #  contents of this data file
      #
      #  NOTE: derived from: dataset istads_id + time_instance istads_id [ + geotime istads_id] +  geog_level istads_id
      #
      dataset_extract_output_name = "_#{self.dataset.istads_id}"
      datatime_extract_output_name = "_#{self.datatime.istads_id}"
      geogtime_extract_output_name = "_#{self.geotime.time_instance.istads_id}"
      geogtime_extract_output_name = "" if geogtime_extract_output_name == datatime_extract_output_name
      geog_level_extract_output_name = "_#{self.geotime.geog_level.abbr}"
      "#{prefix}#{dataset_extract_output_name}#{datatime_extract_output_name}#{geogtime_extract_output_name}#{geog_level_extract_output_name}"
    end

    def root
      DataGroup.find_by_dataset_id_and_geotime_id(dataset, self.geotime.root)
    end

  end
end
