# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class UpdateModisCategoricalToBinary < ActiveRecord::Migration

  def up
    
    execute("DROP FUNCTION IF EXISTS _tp_modis_categorical_binary_summarization(text,bigint,bigint);")
    
    sql0 =<<SQL
    CREATE OR REPLACE FUNCTION _tp_MODIS_categorical_binary_summarization( sample_table_name text, rv_id bigint, raster_bnd bigint)
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, percent double precision, total_area double precision) AS

    $BODY$

        DECLARE

        data_raster text := '';
        area_raster text := '';
        query text := '';
        nodatavalue integer;

        BEGIN

        query  := $$

        WITH lookup AS
        (
            SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
            FROM raster_variables WHERE id IN (
                select raster_variable_classifications.mosaic_raster_variable_id
                from raster_variable_classifications
                where raster_variable_classifications.raster_variable_id = $$ || rv_id || $$ )
        ), geographic_boundaries as
        (
        SELECT tmbb.sample_geog_level_id, tmbb.geog_instance_id, tmbb.geog_instance_label, tmbb.geog_instance_code, geom
        FROM terrapop_modis_binary_boundary tmbb
        ), data_rast AS
        (
        SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code, ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, 255) as rast
        FROM lookup l, geographic_boundaries p inner join modis.igbp r on ST_Intersects(r.rast, p.geom)
        ), total_pixels as
        (
        SELECT geog_id, place_name, place_code, ST_Count(d.rast) as total_pixels
        FROM data_rast d
        ), binary_pixels as
        (
        SELECT geog_id, place_name, place_code, (ST_ValueCount(ST_Reclass(rast,1, l.exp, '8BUI',0))).*
        FROM data_rast, lookup l
        Order by 1
        ), binary_summed as
        (
        SELECT b.geog_id, b.place_name, b.place_code, sum(b.count)::double precision as binary_pixels
        FROM binary_pixels b
        GROUP BY geog_id, place_name, place_code
        ), total_summed as
        (
        SELECT t.geog_id, t.place_name, t.place_code, sum(t.total_pixels)::double precision as total_pixels
        FROM total_pixels t
        GROUP BY geog_id, place_name, place_code
        )
        SELECT b.geog_id::bigint, b.place_name::text, b.place_code, (b.binary_pixels::double precision/t.total_pixels::double precision)::double precision as percent, b.binary_pixels * 214658.671875:: double precision as total_area
        FROM binary_summed b inner join total_summed t on b.geog_id = t.geog_id $$;

        RAISE NOTICE  ' % ', query;
        RETURN QUERY execute query;

        END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;
SQL

    execute(sql0)
  end

  def down
    sql1 =<<SQL
    CREATE OR REPLACE FUNCTION _tp_MODIS_categorical_binary_summarization( sample_table_name text, raster_variable_id bigint, raster_bnd bigint)
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, percent double precision, total_area double precision) AS

    $BODY$

        DECLARE

        data_raster text := '';
        area_raster text := '';
        query text := '';
        nodatavalue integer;

        BEGIN

        SELECT schema || '.' || tablename as tablename
        FROM rasters_metadata_view rmw
        INTO data_raster
        WHERE rmw.id = raster_variable_id;

        RAISE NOTICE '%', data_raster;

        query := $$
        SELECT ST_BandNoDataValue(rast)::integer
        FROM $$ || data_raster || $$
        LIMIT 1 $$ ;

        RAISE NOTICE  ' % ', query;
        Execute query INTO nodatavalue;

        query  := $$

        WITH lookup AS
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
        ), data_rast AS
        (
        SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code, ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, $$ || nodatavalue || $$) as rast
        FROM lookup l, geographic_boundaries p inner join $$ || data_raster || $$ r on ST_Intersects(r.rast, p.geom)
        ), total_pixels as
        (
        SELECT geog_id, place_name, place_code, ST_Count(d.rast) as total_pixels
        FROM data_rast d
        ), binary_pixels as
        (
        SELECT geog_id, place_name, place_code, (ST_ValueCount(ST_Reclass(rast,1, l.exp, '8BUI',0))).*
        FROM data_rast, lookup l
        ), grouping as
        (
        SELECT b.geog_id, b.place_name, b.place_code, sum(t.total_pixels) as total_pixels, sum(b.count) as binary_pixels
        FROM binary_pixels b inner join total_pixels t on b.geog_id = t.geog_id
        GROUP BY b.geog_id, b.place_name, b.place_code
        )
        SELECT geog_id, place_name::text, place_code, binary_pixels/total_pixels::double precision as percent, binary_pixels * 214658.671875:: double precision as total_area
        FROM grouping $$;

        RAISE NOTICE  ' % ', query;
        RETURN QUERY execute query;

        END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;
SQL
    execute(sql1)
  end

end
