# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class AggDataVar < NhgisActiveRecord::Base
    belongs_to :data_table
    
    PAGE_SIZE = 1000
    
    def self.variables_count(dataset_id)
      
      sql =  'select
                COUNT(ds.code) AS count
              from agg_data_vars adv
              join data_tables dt on dt.id = adv.data_table_id
              join datasets ds on ds.id = dt.dataset_id and ds.id = ?
              join data_groups dg on dg.dataset_id = dt.dataset_id AND dg.relative_pathname IS NOT NULL
              join geotimes gt on gt.id = dg.geotime_id
              join geog_levels gl on gl.id = gt.geog_level_id and gl.istads_id IN ("state", "county", "nation")
              join data_files df on df.data_group_id = dg.id
              join time_series_components tsc on tsc.agg_data_var_id = adv.id
              join time_series ts on ts.id= tsc.time_series_id
              join time_series_tables_x_time_series x on x.time_series_id = ts.id
              join time_series_tables tst on tst.id = x.time_series_table_id'
      
      sql = send(:sanitize_sql_array, [sql, dataset_id])
      result = connection.execute(sql)
      
      count = result[0]['count'].to_i
    end
    
    def self.variables(dataset_id, page = -1)
            
      sql =  "select
                ds.code as ds_code,
                dt.label as dt_label,
                adv.label as adv_label,
                adv.id as adv_id,
                ts.id as ts_id,
                ts.label as ts_label,
                tst.id as tst_id,
                tst.label as tst_label,
                gl.id as gl_id,
                gl.istads_id as gl_istads_id,
                dg.id as dg_id,
                dg.relative_pathname as dg_relative_pathname,
                df.id as df_id,
                df.filename as df_filename,
                ds.id as ds_id
              from agg_data_vars adv
              join data_tables dt on dt.id = adv.data_table_id
              join datasets ds on ds.id = dt.dataset_id and ds.id = ?
              join data_groups dg on dg.dataset_id = dt.dataset_id AND dg.relative_pathname IS NOT NULL
              join geotimes gt on gt.id = dg.geotime_id
              join geog_levels gl on gl.id = gt.geog_level_id and gl.istads_id IN ('state', 'county', 'nation')
              join data_files df on df.data_group_id = dg.id
              join time_series_components tsc on tsc.agg_data_var_id = adv.id
              join time_series ts on ts.id= tsc.time_series_id
              join time_series_tables_x_time_series x on x.time_series_id = ts.id
              join time_series_tables tst on tst.id = x.time_series_table_id LIMIT #{page},#{PAGE_SIZE}"
              
              #order by adv.istads_seq'
      
      #connection.execute([sanitize(sql), dataset_id, geog_level_id])
      sql = send(:sanitize_sql_array, [sql, dataset_id])
      connection.execute(sql)
    end
    
    def self.all_variables(limit_dataset_ids = nil)
      
      dataset_ids = limit_dataset_ids.nil? ? Dataset.where({}).select("id") : Dataset.where({id: (limit_dataset_ids.is_a?(Array) ? limit_dataset_ids : [limit_dataset_ids])}).select("id")
      
      file = File.join(TerrapopConfiguration['application']['environments'][Rails.env.to_s]['source_data']['nhgis_metadata'], 'nhgis-agg-data-vars.csv.gz')
      
      
      File.open(file, 'w') do |f|
        gz = Zlib::GzipWriter.new(f)

        csv = CSV.new(gz)
        
        variables = Nhgis::AggDataVar.variables(dataset_ids.first, 0)
        columns = variables.first.keys
        csv << columns
      
        csv.close
      
        gz.close
      end
      
      dataset_ids.each{|dataset|
        
        $stderr.print "===> Working on dataset[#{dataset.id}]..."
        
        count = AggDataVar.variables_count(dataset.id)
        
        pages = (count.to_f/PAGE_SIZE.to_f).ceil

        (0...pages).each{|page|
          variables = AggDataVar.variables(dataset.id, page)
          
          File.open(file, 'a+') do |f|
            gz = Zlib::GzipWriter.new(f)
            csv = CSV.new(gz)
          
            variables.each {|row|
              csv << row.values
            }
          
            csv.close
            gz.close
          end
        }
        
        $stderr.puts "done"
      }
      
      $stderr.puts "==> Done with datasets..."
      
    end
    
  end
end