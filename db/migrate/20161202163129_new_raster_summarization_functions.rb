# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class NewRasterSummarizationFunctions < ActiveRecord::Migration

  def change
    
    sql0 =<<SQL
    CREATE OR REPLACE FUNCTION _tp_MODIS_categorical_binary_summarization( sample_table_name text, raster_variable_id bigint, raster_bnd bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, percent double precision, total_area double precision) AS

    $BODY$

        DECLARE

        data_raster text := '';
        area_raster text := '';
        query text := '';

        BEGIN

        SELECT schema || '.' || tablename as tablename
        FROM rasters_metadata_view rmw
        INTO data_raster
        WHERE rmw.id = raster_variable_id;

        RAISE NOTICE '%', data_raster;

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
    	SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code, ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, 0) as rast
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
    
    sql1 =<<SQL
    CREATE OR REPLACE FUNCTION _tp_continuous_summarization( sample_table_name text, raster_variable_id bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, min double precision, max double precision, mean double precision, count bigint ) AS

    $BODY$

        DECLARE

        data_raster text := '';
        raster_bnd text := '';
        query text := '';
        nodatavalue integer;

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


        query := $$ 
        SELECT ST_BandNoDataValue(rast)::integer
        FROM $$ || data_raster || $$ 
        LIMIT 1 $$ ;
    
        RAISE NOTICE  ' % ', query;
        Execute query INTO nodatavalue;


        query  := $$ WITH geographic_boundaries AS 
        (
        SELECT sample_geog_level_id, geog_instance_id, geog_instance_label, geog_instance_code, geom
        FROM $$ || sample_table_name || $$
        ),
        data_rast AS
        (
        SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code, ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, $$ || nodatavalue || $$) as rast
        FROM geographic_boundaries p inner join $$ || data_raster || $$  r on ST_Intersects(r.rast, p.geom)
        ), summary_rast as
        (
        SELECT d.geog_id, d.place_name, d.place_code, (ST_SummaryStatsAgg(d.rast, 1, True)).*
        FROM data_rast d 
        GROUP BY d.geog_id, d.place_name, d.place_code
        )
        SELECT geog_id, place_name::text, place_code, min, max, mean, count
        FROM summary_rast $$;


    RAISE NOTICE  ' % ', query;
    RETURN QUERY execute query;

    END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;    
SQL
    
    sql2 =<<SQL
    CREATE OR REPLACE FUNCTION _tp_gli_harvested_summarization( sample_table_name text, raster_variable_id bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, percent_area double precision, total_area double precision) AS

    $BODY$

        DECLARE

        data_raster text := '';
        area_raster text := '';
        raster_bnd text := '';
        query text := '';
        nodatavalue integer;

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

        query := $$ 
        SELECT ST_BandNoDataValue(rast)::integer
        FROM $$ || data_raster || $$ 
        LIMIT 1 $$ ;
    
        RAISE NOTICE  ' % ', query;
        Execute query INTO nodatavalue;

        WITH t1 as
        (
        SELECT schema || '.' || tablename as tablename, area_reference_id
        FROM rasters_metadata_view rmw
        WHERE rmw.id = raster_variable_id
        )
        SELECT rmw.schema || '.' || rmw.tablename as area_reference_table
        INTO area_raster
        from rasters_metadata_view rmw, t1
        where rmw.id = t1.area_reference_id;


        query  := $$  WITH geographic_boundaries as
        (
        SELECT sample_geog_level_id, geog_instance_id, geog_instance_label, geog_instance_code, geom
        FROM $$ || sample_table_name || $$
        ), data_rast AS
        (
        SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code, ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, $$ || nodatavalue || $$) as rast
        FROM geographic_boundaries p inner join $$ || data_raster || $$  r on ST_Intersects(r.rast, p.geom)
        ), area_rast AS
        (
        SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code, ST_Clip(r.rast, 1, p.geom, 0) as rast
        FROM geographic_boundaries p inner join $$ || area_raster || $$  r on ST_Intersects(r.rast, p.geom)
        ),calc_rast AS
        (
        SELECT d.geog_id, d.place_name, d.place_code, 
        (ST_SummaryStatsAgg(ST_MapAlgebra(d.rast, 1, a.rast, 1, '[rast1]*[rast2]', '32BF'),1, True)).sum as unit_area, 
        (ST_SummaryStatsAgg(a.rast, 1, True)).sum as total_area
        FROM data_rast d inner join area_rast a on (d.geog_id = a.geog_id) and ST_Intersects(d.rast, a.rast)
        GROUP BY d.geog_id, d.place_name, d.place_code
        )
        SELECT geog_id, place_name::text, place_code, unit_area/total_area as percent_area, total_area
        FROM calc_rast  $$ ;

        RAISE NOTICE  ' % ', query;
        RETURN QUERY execute query;

        END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;
SQL
    
    sql3 =<<SQL
    CREATE OR REPLACE FUNCTION _tp_modis_categorical_summarization( sample_table_name text, raster_variable_id bigint, raster_bnd bigint) 
    RETURNS TABLE (geog_id bigint, place_name text, place_code bigint, mode double precision, num_categories bigint) AS

    $BODY$

    DECLARE

        data_raster text := '';
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

        query := $$ WITH geographic_boundaries AS 
        (
        SELECT sample_geog_level_id, geog_instance_id, geog_instance_label, geog_instance_code, geom
        FROM $$ || sample_table_name || $$
        )
        ,cat_rast AS
        (
        SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code, ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, $$ || nodatavalue || $$) as rast
        FROM geographic_boundaries p inner join $$ ||  data_raster || $$ r on ST_Intersects(r.rast, p.geom)
        order by 1
        ), valuecount_rast  as
        (
        SELECT geog_id, place_name, place_code, (ST_valuecount(rast)).*
        FROM cat_rast 
        )
        , distinct_categories as
        (
        SELECT geog_id, place_name, place_code, value as categories, sum(count) as num_pixels
        -- num_pixel field is not being use, but Josh could use it get the histogram for a specific place
        FROM valuecount_rast
        GROUP BY geog_id, place_name, place_code, value
        ), number_categories as
        (
        select geog_id, place_name, place_code, count(categories) as num_categories
        from distinct_categories
        group by geog_id, place_name, place_code
        )
        , mode_categories as
        (
        SELECT DISTINCT geog_id, place_name, place_code, first_value(categories) OVER w as mode_category, max(num_pixels) OVER w as max_num_pixels
        FROM distinct_categories
        WINDOW w AS ( PARTITION BY geog_id, place_name, place_code ORDER By geog_id, num_pixels DESC)
        )
        SELECT nc.geog_id, nc.place_name::text, nc.place_code, mc.mode_category as mode, nc.num_categories
        FROM number_categories nc
        inner join mode_categories mc on nc.geog_id = mc.geog_id $$;


    RAISE NOTICE  ' % ', query;
    RETURN QUERY execute query;

    END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;
SQL

    execute("DROP FUNCTION IF EXISTS _tp_wgs84_categorical_binary_summarization(text,bigint,bigint)")

    sql4 =<<SQL
    CREATE OR REPLACE FUNCTION _tp_wgs84_categorical_binary_summarization( sample_table_name text, raster_variable_id bigint, raster_bnd bigint) 
    RETURNS TABLE (geog_id bigint, place_name text, place_code bigint, percent_area double precision, total_area double precision) AS

    $BODY$

        DECLARE

        data_raster text := '';
        area_raster text := '';
        raster_bnd text := '';
        query text := '';
        nodatavalue integer;

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

        query := $$ 
        SELECT ST_BandNoDataValue(rast)::integer
        FROM $$ || data_raster || $$ 
        LIMIT 1 $$ ;
    
        RAISE NOTICE  ' % ', query;
        Execute query INTO nodatavalue;


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
        ), data_rast AS
        (
        SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code,
        ST_Reclass(ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, $$ || nodatavalue || $$),1, l.exp, '8BUI',0) as rast
        FROM lookup l, geographic_boundaries p inner join $$ || data_raster || $$  r on ST_Intersects(r.rast, p.geom)
        ), area_rast AS
        (
        SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code, ST_Clip(r.rast, 1, p.geom, 0) as rast
        FROM geographic_boundaries p inner join $$ || area_raster || $$  r on ST_Intersects(r.rast, p.geom)
        ),calc_rast AS
        (
        SELECT d.geog_id, d.place_name, d.place_code, (ST_SummaryStatsAgg(ST_MapAlgebra(d.rast, 1, a.rast, 1, '[rast1]*[rast2]', '32BF'),1, True)).sum as unit_area, 
        (ST_SummaryStatsAgg(a.rast, 1, True)).sum as total_area
        FROM data_rast d inner join area_rast a on (d.geog_id = a.geog_id) and ST_Intersects(d.rast, a.rast)
        GROUP BY d.geog_id, d.place_name, d.place_code
        )
        SELECT geog_id, place_name::text, place_code, unit_area/total_area as percent_area, total_area
        FROM calc_rast  $$ ;

        RAISE NOTICE  ' % ', query;
        RETURN QUERY execute query;

        END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;
SQL

    sql5 =<<SQL
    CREATE OR REPLACE FUNCTION _tp_wgs84_categorical_summarization( sample_table_name text, raster_variable_id bigint, raster_bnd bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, mode double precision, num_categories bigint) AS

    $BODY$

    DECLARE

        data_raster text := '';
        raster_bnd text := '';
        query text := '';
        nodatavalue integer;

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

        query := $$ 
        SELECT ST_BandNoDataValue(rast)::integer
        FROM $$ || data_raster || $$ 
        LIMIT 1 $$ ;
    
        RAISE NOTICE  ' % ', query;
        Execute query INTO nodatavalue;

        query := $$ WITH geographic_boundaries AS 
        (
        SELECT sample_geog_level_id, geog_instance_id, geog_instance_label, geog_instance_code, geom
        FROM $$ || sample_table_name || $$
        ),
        data_rast AS
        (
        SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code, ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, $$ || nodatavalue || $$) as rast
        FROM geographic_boundaries p inner join $$ || data_raster || $$  r on ST_Intersects(r.rast, p.geom)
        ), valuecount_rast  as
        (
        SELECT geog_id, place_name, place_code, (ST_valuecount(rast)).*
        FROM data_rast 
        ), distinct_categories as
        (
        SELECT geog_id, place_name, place_code, value as categories, sum(count) as num_pixels
        FROM valuecount_rast
        GROUP BY geog_id, place_name, place_code, value
        ), number_categories as
        (
        select geog_id, place_name, place_code, count(categories) as num_categories
        from distinct_categories
        group by geog_id, place_name, place_code
        ), mode_categories as
        (
        SELECT DISTINCT geog_id, place_name, place_code, first_value(categories) OVER w as mode_category, max(num_pixels) OVER w as max_num_pixels
        FROM distinct_categories
        WINDOW w AS ( PARTITION BY geog_id, place_name, place_code ORDER By geog_id, num_pixels DESC)
        )
        SELECT nc.geog_id, nc.place_name::text, nc.place_code, mc.mode_category as mode, nc.num_categories
        FROM number_categories nc
        inner join mode_categories mc on nc.geog_id = mc.geog_id $$;

    RAISE NOTICE  ' % ', query;
    RETURN QUERY execute query;

    END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;
SQL

    sql6 =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_MODIS_categorical_binary_summarization( sample_geog_level_id bigint, raster_variable_id bigint, raster_bnd bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, percent double precision, total_area double precision) AS

    $BODY$

    DECLARE

        data_raster text := '';
        query text := '';

        BEGIN

        SELECT schema || '.' || tablename as tablename
        FROM rasters_metadata_view rmw
        INTO data_raster
        WHERE rmw.id = raster_variable_id;

        RAISE NOTICE '%', data_raster;

        DROP TABLE IF EXISTS terrapop_modis_binary_boundary;

        query := $$ CREATE TEMP TABLE terrapop_modis_binary_boundary AS
        WITH raster_projection AS
        (
        select st_srid(rast) as prj
        from $$ || data_raster || $$ 
        limit 1
        )
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, gi.code as geog_instance_code, ST_Transform(bound.geom, prj.prj) as geom,
        ST_IsValidReason(ST_Transform(bound.geom, prj.prj)) as reason
        FROM raster_projection prj,
        sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = $$ || sample_geog_level_id || $$ $$;

        RAISE NOTICE  ' % ', query;

        EXECUTE query;

        Update terrapop_modis_binary_boundary
        SET geom = ST_MakeValid(geom)
        WHERE reason <> 'Valid Geometry';

        DELETE FROM terrapop_modis_binary_boundary
        WHERE ST_IsValidReason(geom) <> 'Valid Geometry';

        RETURN QUERY
    	SELECT * FROM _tp_MODIS_categorical_binary_summarization('terrapop_modis_binary_boundary'::text, raster_variable_id, raster_bnd );


    END;

    $BODY$

    LANGUAGE plpgsql VOLATILE
    COST 100;
SQL

    sql7 =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_continuous_summarization( sample_geog_level_id bigint, raster_variable_id bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, min double precision, max double precision, mean double precision, count bigint ) AS

    $BODY$

        DECLARE

        data_raster text := '';
        raster_bnd bigint;
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


        DROP TABLE IF EXISTS terrapop_continuous_boundary;

        query := $$ CREATE TEMP TABLE terrapop_continuous_boundary AS
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, gi.code as geog_instance_code, bound.geom as geom,
        ST_IsValidReason(bound.geom) as reason
        FROM sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = $$ || sample_geog_level_id || $$ $$;

        RAISE NOTICE  ' % ', query;

        EXECUTE query;

        Update terrapop_continuous_boundary
        SET geom = ST_MakeValid(geom)
        WHERE reason <> 'Valid Geometry';

        DELETE FROM terrapop_continuous_boundary
        WHERE ST_IsValidReason(geom) <> 'Valid Geometry';

        RETURN QUERY SELECT * FROM _tp_continuous_summarization('terrapop_continuous_boundary'::text, raster_variable_id );



    END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;
SQL
    
    sql8 =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_gli_harvested_summarization( sample_geog_level_id bigint, raster_variable_id bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, percent_area double precision, total_area double precision) AS

    $BODY$

        DECLARE

        data_raster text := '';
        area_raster text := '';
        raster_bnd text := '';
        query text := '';

        BEGIN

        DROP TABLE IF EXISTS terrapop_gli_harvestedarea_boundary;

        query := $$ CREATE TEMP TABLE terrapop_gli_harvestedarea_boundary AS
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, gi.code as geog_instance_code, bound.geom as geom,
        ST_IsValidReason(bound.geom) as reason
        FROM sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = $$ || sample_geog_level_id || $$ $$;

        RAISE NOTICE  ' % ', query;

        EXECUTE query;

        Update terrapop_gli_harvestedarea_boundary
        SET geom = ST_MakeValid(geom)
        WHERE reason <> 'Valid Geometry';

        DELETE FROM terrapop_gli_harvestedarea_boundary
        WHERE ST_IsValidReason(geom) <> 'Valid Geometry';

        RETURN QUERY
        SELECT * FROM _tp_gli_harvested_summarization('terrapop_gli_harvestedarea_boundary'::text, raster_variable_id );

        END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;
SQL

    sql9 =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_modis_categorical_summarization( sample_geog_level_id bigint, raster_variable_id bigint, raster_bnd bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, mode double precision, num_categories bigint) AS

    $BODY$

    DECLARE

        data_raster text := '';
        query text := '';

        BEGIN

        SELECT schema || '.' || tablename as tablename
        FROM rasters_metadata_view rmw
        INTO data_raster
        WHERE rmw.id = raster_variable_id;

        RAISE NOTICE '%', data_raster;

        DROP TABLE IF EXISTS terrapop_modis_boundary;

        query := $$ CREATE TEMP TABLE terrapop_modis_boundary AS
        WITH raster_projection AS
        (
        select st_srid(rast) as prj
        from $$ || data_raster || $$ 
        limit 1
        )
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, gi.code as geog_instance_code, ST_Transform(bound.geom, prj.prj) as geom,
        ST_IsValidReason(ST_Transform(bound.geom, prj.prj)) as reason
        FROM raster_projection prj,
        sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = $$ || sample_geog_level_id || $$ $$;

        RAISE NOTICE  ' % ', query;

        EXECUTE query;

        Update terrapop_modis_boundary
        SET geom = ST_MakeValid(geom)
        WHERE reason <> 'Valid Geometry';

        DELETE FROM terrapop_modis_boundary
        WHERE ST_IsValidReason(geom) <> 'Valid Geometry';

        RETURN QUERY SELECT * FROM _tp_categorical_modis_summarization('terrapop_modis_boundary', raster_variable_id, raster_bnd );


    END;

    $BODY$

    LANGUAGE plpgsql VOLATILE
    COST 100;
SQL

    sql10 =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_wgs84_categorical_binary_summarization( sample_geog_level_id bigint, raster_variable_id bigint, raster_bnd bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, percent_area double precision, total_area double precision) AS

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

    sql11 =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_wgs84_categorical_summarization( sample_geog_level_id bigint, raster_variable_id bigint, raster_bnd bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, mode double precision, num_categories bigint) AS

    $BODY$

    DECLARE

        data_raster text := '';
        query text := '';
        terrapop_boundaries record;
        rec record;

        BEGIN

        SELECT schema || '.' || tablename as tablename
        FROM rasters_metadata_view nw
        INTO data_raster
        WHERE nw.id = raster_variable_id;

        RAISE NOTICE '%', data_raster;

        DROP TABLE IF EXISTS terrapop_wgs_boundary;

        query := $$ CREATE TEMP TABLE terrapop_wgs_boundary AS
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, gi.code as geog_instance_code, bound.geom as geom,
        ST_IsValidReason(bound.geom) as reason
        FROM sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = $$ || sample_geog_level_id || $$ $$;

        RAISE NOTICE  ' % ', query;

        EXECUTE query;

        Update terrapop_wgs_boundary
        SET geom = ST_MakeValid(geom)
        WHERE reason <> 'Valid Geometry';

        DELETE FROM terrapop_wgs_boundary
        WHERE ST_IsValidReason(geom) <> 'Valid Geometry';

        RETURN QUERY SELECT * FROM _tp_wgs84_categorical_summarization('terrapop_wgs_boundary', raster_variable_id, raster_bnd );


    END;

    $BODY$

    LANGUAGE plpgsql VOLATILE
    COST 100;
SQL
    
    execute(sql0)
    execute(sql1)
    execute(sql2)
    execute(sql3)
    execute(sql4)
    execute(sql5)
    execute(sql6)
    execute(sql7)
    execute(sql8)
    execute(sql9)
    execute(sql10)
    execute(sql11)
    
  end
end
