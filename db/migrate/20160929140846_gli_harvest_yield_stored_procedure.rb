# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class GliHarvestYieldStoredProcedure < ActiveRecord::Migration

  def change
    
    sql=<<SQL
    CREATE OR REPLACE FUNCTION terrapop_continous_summarization_10052016( sample_geog_level_id bigint, raster_variable_id bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, min double precision, max double precision, mean double precision, count bigint ) AS

    $BODY$

        DECLARE

        data_raster text := '';
        raster_bnd text := '';
        query text := '';

        BEGIN

        SELECT schema || '.' || tablename as tablename
        FROM rasters_metadata_view nw
        INTO data_raster
        WHERE nw.id = raster_variable_id;

        RAISE NOTICE '%', data_raster;

        SELECT band_num
        FROM rasters_metadata_view nw
        INTO raster_bnd
        WHERE nw.id = raster_variable_id;

        RAISE NOTICE 'band: %', raster_bnd;


        query  := $$ WITH geographic_boundaries AS 
        (
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, gi.code as geog_instance_code, bound.geog::geometry as geom
        FROM sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = $$ || sample_geog_level_id || $$
        ),
        data_rast AS
        (
        SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code, ST_Union(ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, 0)) as rast
        FROM geographic_boundaries p inner join $$ || data_raster || $$  r on ST_Intersects(r.rast, p.geom)
        GROUP BY p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
        ), summary_rast as
        (
        SELECT  d.geog_id, d.place_name, d.place_code, (ST_SummaryStats(d.rast)).*
        FROM data_rast d 
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
      
    execute(sql)

  end
end
