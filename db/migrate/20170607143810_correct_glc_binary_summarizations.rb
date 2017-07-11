# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CorrectGlcBinarySummarizations < ActiveRecord::Migration

  def change
    
    execute("DROP FUNCTION IF EXISTS _tp_wgs84_categorical_binary_summarization(text,bigint,bigint)")
    execute("DROP FUNCTION IF EXISTS _tp_wgs84_categorical_binary_summarization(text,bigint,bigint,bigint)")
    
    
    sql0 =<<SQL
    CREATE OR REPLACE FUNCTION _tp_wgs84_categorical_binary_summarization( sample_table_name text, sample_geog_level_id bigint, raster_variable_id bigint, raster_bnd bigint) 
    RETURNS TABLE (geog_id bigint, place_name text, place_code bigint, percent_area double precision, total_area double precision, total_geog_area double precision) AS

    $BODY$

        DECLARE

        data_raster text := '';
        area_raster text := '';
        raster_bnd text := '';
        query text := '';
        arearef_variable_id bigint := 0;
        
        BEGIN

        SELECT schema || '.' || tablename as tablename
        FROM rasters_metadata_view rmw
        INTO data_raster
        WHERE rmw.id = raster_variable_id;

        RAISE NOTICE '%', data_raster;

        SELECT band_num
        FROM rasters_metadata_view rmw
        INTO raster_bnd
        WHERE rmw.id = raster_variable_id;

        RAISE NOTICE 'band: %', raster_bnd;


        WITH t1 as
        (
        SELECT schema || '.' || tablename as tablename, area_reference_id
        FROM new_rasters rmw
        WHERE rmw.id = raster_variable_id
        )
        SELECT rmw.schema || '.' || rmw.tablename as area_reference_table
        INTO area_raster
        from new_rasters rmw, t1
        where rmw.id = t1.area_reference_id;
        
        SELECT area_reference_id INTO arearef_variable_id FROM raster_variables rv WHERE rv.id = raster_variable_id;

        query  := $$  WITH lookup AS
        (
            SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
            FROM raster_variables WHERE id IN (
                    select raster_variable_classifications.mosaic_raster_variable_id 
                    from raster_variable_classifications
                    where raster_variable_classifications.raster_variable_id = $$ || raster_variable_id || $$)
        ), geographic_boundaries as
        (
        SELECT sample_geog_level_id, geog_instance_id, geog_instance_label, geog_instance_code, geom
        FROM $$ || sample_table_name || $$
        ), 
      
        data_rast AS
        (
          SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code,
          ST_Reclass(ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, ST_BandNoDataValue(r.rast) ),1, l.exp, '8BUI',0) as rast
          FROM lookup l, geographic_boundaries p inner join $$ || data_raster || $$  r on ST_Intersects(r.rast, p.geom)
        ),
      
        area_rast AS
        (
          SELECT p.geog_instance_id as geog_id,  
            ST_Clip(r.rast, p.geom, ST_BandNoDataValue(r.rast)) AS rast
            FROM geographic_boundaries p inner join $$ || area_raster || $$ r on ST_Intersects(r.rast, p.geom)
        ),
        calc_data_rast AS (
          SELECT d.geog_id, (ST_SummaryStatsAgg(ST_MapAlgebra(d.rast, 1, a.rast, 1, '[rast1]*[rast2]'::text, '32BF'::text),1, True)).sum as unit_area FROM 
            data_rast d JOIN area_rast a ON ST_Intersects(d.rast, a.rast) GROUP BY d.geog_id
        ),
        total_arearef AS (
          SELECT * FROM terrapop_area_reference_summarization( $$ || sample_geog_level_id || $$, $$ || arearef_variable_id || $$)
        ),
        calc_rast AS
        (
          SELECT d.geog_id, d.place_name, d.place_code, cdr.unit_area, 
          --(ST_SummaryStatsAgg(a.rast, 1, True)).sum as total_area
          --(ST_SummaryStats(ST_Union(a.rast))).sum as total_area
          ta.total_area
          FROM data_rast d 
            join area_rast a on (d.geog_id = a.geog_id)
            join calc_data_rast cdr on (d.geog_id = cdr.geog_id)
            join total_arearef ta ON (d.geog_id = ta.geog_instance_id)
          GROUP BY d.geog_id, d.place_name, d.place_code, cdr.unit_area, ta.total_area
        )
        SELECT geog_id, place_name::text, place_code, unit_area/total_area as percent_area, unit_area, total_area
        FROM calc_rast  $$ ;

        RAISE NOTICE  ' % ', query;
        RETURN QUERY execute query;

        END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;
SQL

  sql1 =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_wgs84_categorical_binary_summarization_v11302016( sample_geog_level_id bigint, raster_variable_id bigint, raster_bnd bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, percent_area double precision, total_area double precision, total_geog_area double precision) AS

    $BODY$

        DECLARE

        data_raster text := '';
        area_raster text := '';
        raster_bnd bigint := 1;
        query text := '';

        BEGIN

        SELECT schema || '.' || tablename as tablename
        FROM rasters_metadata_view nw
        INTO data_raster
        WHERE nw.id = raster_variable_id;

        RAISE NOTICE '%', data_raster;

        SELECT band_num::bigint
        FROM rasters_metadata_view nw
        INTO raster_bnd
        WHERE nw.id = raster_variable_id;

        RAISE NOTICE 'band: %', raster_bnd;

        DROP TABLE IF EXISTS terrapop_wgs84_binary_boundary;

        query := $$ CREATE TEMP TABLE terrapop_wgs84_binary_boundary AS
         SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, gi.code as geog_instance_code, 
         bound.geom as geom, ST_IsValidReason(bound.geom) as reason
        FROM sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = $$ || sample_geog_level_id || $$ $$;

        RAISE NOTICE  ' % ', query;

        EXECUTE query;

        Update terrapop_wgs84_binary_boundary
        SET geom = ST_MakeValid(geom)
        WHERE reason <> 'Valid Geometry';

        DELETE FROM terrapop_wgs84_binary_boundary
        WHERE ST_IsValidReason(geom) <> 'Valid Geometry';

        RETURN QUERY
        SELECT * FROM _tp_wgs84_categorical_binary_summarization('terrapop_wgs84_binary_boundary'::text, sample_geog_level_id, raster_variable_id, raster_bnd );

        END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;    
SQL

    drop_sql0 = "DROP FUNCTION IF EXISTS terrapop_wgs84_categorical_binary_summarization_v11302016(bigint,bigint,bigint);"
    drop_sql1 = "DROP FUNCTION IF EXISTS _tp_wgs84_categorical_binary_summarization(text,bigint,bigint,bigint);"

    execute(drop_sql0)
    execute(drop_sql1)
    
    execute(sql0)
    execute(sql1)
    
  end
end
