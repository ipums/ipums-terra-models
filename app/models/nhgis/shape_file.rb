# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis

  class ShapeFile < NhgisActiveRecord::Base

    belongs_to :geotime
    belongs_to :geog_name
    belongs_to :source_type
    belongs_to :resolution
    belongs_to :integ_geog_level

    def self.shape_file_information(relative_pathname, filename)

      sql = <<-SQL_O_MATIC
select sf.geog_label, sf.cached_year_label, st.directory_name as source_dir, sf.id, sf.filename, sf.relative_pathname, sf.description, sf.*,
gt.time_instance_id, gt.geog_level_id, gl.istads_id
from shape_files sf
join geotimes gt on gt.id = sf.geotime_id
join geog_levels gl on gl.id = gt.geog_level_id and gl.istads_id in ("nation", "state", "county", "tract")
join source_types st on st.id = sf.source_type_id
WHERE sf.relative_pathname = ? AND sf.filename = ?
order by geog_label, cached_year_label, st.directory_name
      SQL_O_MATIC

      sql = ShapeFile.send(:sanitize_sql_array, [sql, relative_pathname, filename])

      connection.execute(sql).to_a
    end


    def self.popscore_temp_table_name
      "TEMP_pop_shp"
    end

    def self.popscore_csv_file_name
      "popscores_shape_files.csv"
    end

    def self.ids_from_filters(ds_list, gl_list, ti_list, tp_list, tp_as_bv_list, kw_list, tp_operator, gl_operator, ti_operator)
      # shortcut 2 (like the one in paginated_rows_from_filters below)   -- TODO: refactor opportunity
      if tp_list.size > 0 || tp_as_bv_list.size > 0 || kw_list.size > 0
        ds_list = Dataset.get_istads_ids_for_keywords_topics(ds_list, kw_list, tp_list, tp_as_bv_list, tp_operator, ti_operator)
        return [] if ds_list.size == 0
      end

      # FIXME - is this a correct assumption, ongoing, w/future integration work??
      # shortcut 1: we 'know' with multiple years AND'd there will be no boundary files
      if ti_list.size > 1 && ti_operator == "AND"
        return []
      end

      sqlbld = sql_from_filters(ds_list, gl_list, ti_list, ti_operator, nil, nil)
      sql = sqlbld.sql
      RunSqlRun.return_array(sql).map{|r| r['id']}
    end


    def self.paginated_rows_from_filters(filter_selections, page, per_page, sort_index, sort_order, ignore1, ignore2=nil, ignore3=nil)
      ds_list = filter_selections.filtered_datasets
      gl_list = filter_selections.filtered_geog_levels
      ti_list = filter_selections.filtered_years
      tp_list = filter_selections.filtered_topics
      tp_as_bv_list = filter_selections.filtered_topics_as_breakdowns
      kw_list = filter_selections.filtered_keywords
      tp_operator = filter_selections.filtered_topics_operator
      ti_operator = filter_selections.filtered_years_operator

      # FIXME - is this a correct assumption, ongoing, w/future integration work??
      # shortcut 1: we 'know' with multiple years AND'd there will be no boundary files
      if ti_list.size > 1 && ti_operator == "AND"
        # TODO: include a max-pop-score entry, possibly w/1.0 or some default - value doesn't matter
        return GridPaginate.new([], 0, per_page)
      end
      # shortcut 2:
      if tp_list.size > 0 || tp_as_bv_list.size > 0 || kw_list.size > 0
        ds_list = Dataset.get_istads_ids_for_keywords_topics(ds_list, kw_list, tp_list, tp_as_bv_list, tp_operator, ti_operator)
        # TOOD: in this case, max-pop-score comes from sister method, paginated_rows_from_istads_ids
        return paginated_rows_from_istads_ids([], page, per_page, sort_index, sort_order) if ds_list.size == 0
      end
      sqlbld = sql_from_filters(ds_list, gl_list, ti_list, ti_operator, sort_index, sort_order)

      # Part I - rowcount
      sql = sqlbld.sql
      query = sanitize_sql(sql.dup)
      rowcount, dummy = find_by_sql(query).size.to_i  # max_pop_score not being set here (yet!)

      # Part II - max population score
      sql = sqlbld.sql_override_selects_no_order_by(["COUNT(sf.id) AS count", "MAX(sf.popularity_score) AS maxpop"])
      query = sanitize_sql(sql.dup)
      answer =  RunSqlRun.return_array(query)[0]
      dummy, max_pop_score = answer["count"], answer["maxpop"]

      rows = paginated_grid_rows_query(page, per_page) do
        sqlbld.selects << "#{max_pop_score} AS `max_popularity_score`" if !max_pop_score.nil?
        sqlbld.sql
      end
      GridPaginate.new(rows, rowcount, per_page)
    end

    def self.paginated_rows_from_istads_ids(istads_ids, page, per_page, sort_index, sort_order)
      return GridPaginate.new([], 0, per_page) if istads_ids.empty?
      sqlbld = sql_from_istads_ids(istads_ids, sort_index, sort_order)

      # Part I - rowcount
      rowcount, dummy = total_row_count_query { sqlbld.sql }

      # Part II - max population score
      sql = sqlbld.sql_override_selects_no_order_by(["COUNT(sf.id) AS count", "MAX(sf.popularity_score) AS maxpop"])
      query = sanitize_sql(sql.dup)
      answer =  RunSqlRun.return_array(query)[0]
      dummy, max_pop_score = answer["count"], answer["maxpop"]

      rows = paginated_grid_rows_query(page, per_page) do
        sqlbld.selects << "#{max_pop_score} AS `max_popularity_score`" if !max_pop_score.nil?
        sqlbld.sql
      end
      GridPaginate.new(rows, rowcount, per_page)
    end

    def extract_output_filename
      #TODO add base vs. integ when integrated shapefiles are deployed (and added to the metadata) krh 2/19/20131
      #TODO add generalizations (or nongen) when generalized shapefiles are deployed (and added to the metadata) krh 2/19/20131
      "#{source_type.directory_name}_#{filename}"
    end

    private

    def self.sql_from_istads_ids(istads_ids, sort_index, sort_order)
      sqlbld = SqlBuilder.new
      sqlbld.from = "shape_files sf"

      sqlbld.selects << "sf.*"
      #sqlbld.selects << "#{maxpop} AS `max_popularity_score`"
      sqlbld.selects << "st.istads_id AS `source_type_istads_id`"
      sqlbld.selects << "st.label AS `source_type_label`"

      sqlbld.joins << "JOIN source_types st ON st.id = sf.source_type_id"
      sqlbld.criteria << "sf.istads_id in ('#{istads_ids.join("', '")}')"
      unless sort_index.nil?
        given_order = sort_index
        given_order << " #{sort_order}" unless sort_order.nil?
        sqlbld.order_by << given_order
        sqlbld.order_by << "sf.istads_seq"
        sqlbld.order_by.uniq!
      end

      sqlbld
    end

    def self.sql_from_filters(ds_list, gl_list, ti_list, ti_operator, sort_index, sort_order)
      ds_list = [] unless ds_list  # list of dataset istads_ids (strings)
      gl_list = [] unless gl_list  # list of geog_level istads_ids (strings)
      ti_list = [] unless ti_list  # list of time_instance istads_ids (strings, possibly interpreted as integers)

      sqlbld = SqlBuilder.new
      sqlbld.from = "shape_files sf"

      sqlbld.selects << "sf.*"
      sqlbld.selects << "st.istads_id AS `source_type_istads_id`"
      sqlbld.selects << "st.label AS `source_type_label`"

      sqlbld.joins << "JOIN source_types st ON st.id = sf.source_type_id"
      if gl_list.size > 0 || ds_list.size > 0 || ti_list.size > 0
        sqlbld.joins << "JOIN geotimes gt ON sf.geotime_id = gt.id"
        if gl_list.size > 0
          sqlbld.joins << "JOIN geog_levels gl ON gl.id = gt.geog_level_id"
          sqlbld.criteria << "gl.istads_id in ('#{gl_list.join("', '")}')"
        end
        if ds_list.size > 0 || ti_list.size > 0
          join_statement = "JOIN data_groups dg ON dg.geotime_id = gt.id and dg.relative_pathname is not NULL"
          join_statement = "LEFT #{join_statement}" if ds_list.empty?     #if the dataset list is empty, then the data_groups join must be a LEFT JOIN
          sqlbld.joins << join_statement

          if ds_list.size > 0
            sqlbld.joins << "JOIN datasets ds ON dg.dataset_id = ds.id"
            sqlbld.criteria << "ds.istads_id in ('#{ds_list.join("', '")}')"
          end
          if ti_list.size > 0
            sqlbld.joins << "JOIN time_instances ti_geog ON ti_geog.id = gt.time_instance_id"
            join_statement = "JOIN time_instances ti_data ON ti_data.id = dg.datatime_id"
            join_statement = "LEFT #{join_statement}" if ds_list.empty?   #if the dataset list is empty, then the time_instances join must be a LEFT JOIN
            sqlbld.joins << join_statement
            sqlbld.criteria << "(ti_data.istads_id in ('#{ti_list.join("', '")}') OR ti_geog.istads_id in ('#{ti_list.join("', '")}'))"

            if ti_list.size > 1 && ti_operator == "AND"
              sqlbld.having << "COUNT(DISTINCT sf.cached_year_label) = #{ti_list.size}"
            end
          end
        end
      end
      unless sort_index.nil?
        given_order = sort_index
        given_order += " #{sort_order}" unless sort_order.nil?
        sqlbld.order_by << given_order
        sqlbld.order_by << "sf.istads_seq"
        sqlbld.order_by.uniq!
      end

      sqlbld
    end

  end
end
