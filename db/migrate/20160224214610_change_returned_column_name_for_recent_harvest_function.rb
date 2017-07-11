# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class ChangeReturnedColumnNameForRecentHarvestFunction < ActiveRecord::Migration

  def change
    sql = <<SQL
    CREATE OR REPLACE FUNCTION terrapop_gli_harvest_areal_summarization_v6(IN sample_geog_lvl_id bigint, IN rasters_id bigint)
          RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying,  geog_instance_code numeric, percent_area double precision, harvest_area double precision, total_area double precision) AS
        $BODY$

        DECLARE

        data_raster text := '';
        area_raster text := '';
        query text := '';

        BEGIN

        SELECT r_table_schema || '.' || table_name as tablename
        FROM new_rasters nw
        INTO data_raster
        WHERE nw.raster_variable_id = rasters_id;

        RAISE NOTICE '%', data_raster;

        WITH t1 as
        (
        SELECT r_table_schema || '.' || table_name as tablename, area_reference_id
        FROM new_rasters nw
        WHERE nw.raster_variable_id = rasters_id
        )
        SELECT r_table_schema || '.' || table_name as area_reference_table
        INTO area_raster
        from new_rasters nw, t1
        where nw.raster_variable_id = t1.area_reference_id;

        RAISE NOTICE '%', area_raster;

        query := $$ WITH metadata_raster as
        (
        SELECT st_srid(r.rast) as srid
        FROM rasters r
        where r.raster_variable_id = $$ ||rasters_id || $$
        limit 1
        ), bounds as
        (
        SELECT sgl.id as sample_geog_level_id, gi.id as gid, gi.label as label, gi.code as geog_instance_code, st_transform(bound.geog::geometry, md.srid) as geom
        FROM metadata_raster md, sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id inner join boundaries bound on bound.geog_instance_id = gi.id
        where sgl.id = $$ || sample_geog_lvl_id || $$
        ), data_rast as
        (
        SELECT b.gid as gid, b.label as label, b.geog_instance_code, ST_Union(ST_Clip(r.rast, b.geom)) as rast
        FROM bounds b inner join $$ || data_raster || $$ r on ST_Intersects(r.rast, b.geom)
        GROUP BY b.gid, b.label,  b.geog_instance_code
        ), area_ref_rast as
        (
        SELECT b.gid as gid, b.label as label, b.geog_instance_code, ST_Union(ST_Clip(r.rast, b.geom)) as rast
        FROM bounds b inner join $$ || area_raster || $$ r on ST_Intersects(r.rast, b.geom)
        GROUP BY b.gid, b.label,  b.geog_instance_code
        ), summary_rast as
        (
        SELECT d.gid, d.label, d.geog_instance_code,
        (ST_SummaryStats(ST_MapAlgebra(d.rast, 1, a.rast, 1,'[rast1]*[rast2]'))).sum as hectar_area,
        (ST_SummaryStats(a.rast)).sum as total_area
        FROM data_rast d 
        inner join area_ref_rast a on d.gid = a.gid
        )
        SELECT s.gid::bigint, s.label, s.geog_instance_code::numeric, (s.hectar_area/s.total_area) as percent_area, s.hectar_area as harvested_area, s.total_area
        FROM summary_rast s
        $$;

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
