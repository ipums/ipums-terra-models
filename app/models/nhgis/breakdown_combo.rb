# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class BreakdownCombo < NhgisActiveRecord::Base

    has_many :data_files
    has_many :time_series_components
    has_many :breakdown_value_breakdown_combos
    has_many :breakdown_values,:through=>:breakdown_value_breakdown_combos
  
    def self.istads_ids_for_sql(breakdown_value_istads_id_list)
      #this method will convert an array of breakdown value istads id into a string that can be used in a sql statement
      breakdown_value_istads_id_list.inspect.gsub("[", "").gsub("]", "").gsub("\"", "'")
    end

    def self.defaults
      sql =<<-EOS
          SELECT bc.*
          FROM breakdown_combos bc
          JOIN breakdown_values_x_breakdown_combos x ON x.breakdown_combo_id = bc.id
          JOIN breakdown_values bv                   ON bv.id = x.breakdown_value_id
          GROUP BY bc.id HAVING COUNT(bv.id) = SUM(is_default);
      EOS
      find_by_sql(sql)
    end

    def self.find_by_breakdown_values(breakdown_value_istads_ids)
      # there is an assumption that breakdown_value_istads_ids will contain the istads ids belonging to...
      #    NO breakdown value set (when empty),
      #    one breakdown value set (when breakdown value istads ids begin with the SAME prefix e.g. "bs01"
      #    two breakdown value sets (when breakdown value istads ids begin with one prefix or another e.g. "bs01" or "bs02"
      # ASSUMPTION is that there is never a valid breakdown combo where

      #puts "*** In find_by_breakdown_values #{breakdown_value_istads_ids.inspect}"
      breakdown_value_sets = breakdown_value_istads_ids.map{|bv|
      bv.
      split(".").
      first}.flatten.uniq
    
      case breakdown_value_sets.size
        when 0
          return []
        when 1
          sql_values = BreakdownCombo.istads_ids_for_sql(breakdown_value_istads_ids) 
          sql = "SELECT DISTINCT * FROM breakdown_combos WHERE istads_id IN (#{sql_values})"
        when 2
          bs1 = breakdown_value_sets.first
          bs2 = breakdown_value_sets.last
          bvs1 = breakdown_value_istads_ids.select{|bv| bv.split(".").first == bs1}
          bvs2 = breakdown_value_istads_ids.select{|bv| bv.split(".").first == bs2}
          sql_values1 = BreakdownCombo.istads_ids_for_sql(bvs1)
          sql_values2 = BreakdownCombo.istads_ids_for_sql(bvs2)

          sql = "SELECT DISTINCT bc.* FROM breakdown_combos bc "
          sql << "JOIN breakdown_values_x_breakdown_combos x ON x.breakdown_combo_id = bc.id "
          sql << "JOIN breakdown_values bv ON bv.id = x.breakdown_value_id AND bv.istads_id LIKE '#{bs1}.%' "
          sql << "JOIN breakdown_values_x_breakdown_combos x2 ON x2.breakdown_combo_id = x.breakdown_combo_id "
          sql << "JOIN breakdown_values bv2 ON bv2.id = x2.breakdown_value_id AND bv2.istads_id LIKE '#{bs2}.%' "
          sql << "WHERE bv.istads_id IN (#{sql_values1}) AND bv2.istads_id IN (#{sql_values2})"
        else
          raise "too many breakdown value sets; only expected 1 or 2 (or none)"
      end
      find_by_sql(sql)
    end

    def codebook_labels
      sorted_breakdown_values.map{|bv| bv.composite_codebook_label}
    end

    def header_label
      #"[breakdown_var 1 value]: [breakdown_var 2 value]"
      # NOTE : currently sorting the breakdowns using the breakdown value set istads_id
      sorted_breakdown_values.map{|bv| bv.label}.join(": ")
    end

    def is_default?
      breakdown_values.each{|bv| return false unless bv.is_default}
      return true
    end

    def sorted_breakdown_values
      breakdown_values.sort{|a,b| a.breakdown_value_set.istads_seq <=> b.breakdown_value_set.istads_seq}
    end
  end
end