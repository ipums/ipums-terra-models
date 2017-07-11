# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRastersMetadataView < ActiveRecord::Migration


  def up
    
    sql=<<SQL
    DROP VIEW IF EXISTS rasters_metadata_view;
SQL
    execute(sql)
    
    sql=<<SQL
CREATE OR REPLACE VIEW rasters_metadata_view AS
 WITH loaded_rasters AS (
         SELECT lower(raster_columns.r_table_schema::text) AS schema,
            lower(raster_columns.r_table_name::text) AS tablename,
            raster_columns.srid
           FROM raster_columns
          WHERE raster_columns.r_table_schema <> 'gis_rasters'::name
        ), raster_metadata AS (
         SELECT rv.id,
            rv.mnemonic,
            lower(rtn.schema::text) AS schema,
            lower(rtn.tablename::text) AS tablename,
            rb.band_num,
            rv.area_reference_id,
            rv.second_area_reference_id,
            rdt.code AS mnemonic_type
           FROM raster_table_names rtn
             JOIN raster_bands rb ON rtn.id = rb.raster_table_name_id
             JOIN raster_variable_raster_bands rvrb ON rb.id = rvrb.raster_band_id
             JOIN raster_variables rv ON rvrb.raster_variable_id = rv.id
             JOIN raster_data_types rdt ON rv.raster_data_type_id = rdt.id
        ), all_data AS (
         SELECT rm.id,
            rm.mnemonic,
            rm.schema,
            rm.tablename,
            rm.band_num,
            lr.schema AS loaded_schema,
            lr.tablename AS loaded_table,
            lr.srid,
            rm.area_reference_id,
            rm.second_area_reference_id,
            rm.mnemonic_type
           FROM raster_metadata rm
             LEFT JOIN loaded_rasters lr ON rm.schema = lr.schema AND rm.tablename = lr.tablename
        )
 SELECT all_data.id,
    all_data.mnemonic,
    all_data.schema,
    all_data.tablename,
    all_data.band_num,
    all_data.srid,
    all_data.area_reference_id,
    all_data.second_area_reference_id,
    all_data.mnemonic_type,
        CASE
            WHEN all_data.loaded_table <> ''::text THEN 1
            ELSE NULL::integer
        END::boolean AS data_exists
   FROM all_data;
SQL
    execute(sql)
  end

  def down
    sql=<<SQL
    DROP VIEW rasters_metadata_view;
SQL
    execute(sql)
  end

end
