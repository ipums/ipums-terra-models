# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class ModisBinaryToCategorical < ActiveRecord::Migration

  def change
    # RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, pixel_count bigint, binary_area double precision, percent_area double precision, total_area double precision) AS
    sql = <<SQL
    CREATE OR REPLACE FUNCTION terrapop_MODIS_categorical_binary_summarization_v09282016( sample_geog_level_id bigint, raster_variable_id bigint, raster_bnd bigint) 
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label text, code bigint, percent_area double precision, total_area double precision, binary_area double precision, binary_pixel_count bigint, total_pixels bigint ) AS

    $BODY$

        DECLARE

        data_raster text := '';
        area_raster text := '';
        query text := '';

        BEGIN

        SELECT schema || '.' || tablename as tablename
        FROM rasters_metadata_view nw
        INTO data_raster
        WHERE nw.id = raster_variable_id;

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
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, gi.code as geog_instance_code, st_transform(bound.geog::geometry,106842) as geom
        FROM sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = $$ || sample_geog_level_id || $$
        ), data_rast AS
      (
      SELECT p.geog_instance_id as geog_id, p.geog_instance_label as place_name, p.geog_instance_code as place_code, 
      ST_Union(ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, 0)) as rast
      FROM lookup l, geographic_boundaries p inner join $$ || data_raster || $$  r on ST_Intersects(r.rast, p.geom)
      GROUP BY p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
      ), total_pixels as
      (
      SELECT geog_id, place_name, place_code, ST_Count(d.rast) as total_pixels
      FROM data_rast d
      ), binary_pixels as
      (
      SELECT geog_id, place_name, place_code, (ST_ValueCount(ST_Reclass(rast,1, l.exp, '8BUI',0))).*
      FROM data_rast, lookup l
      )
      SELECT b.geog_id, b.place_name::text, b.place_code, b.count/t.total_pixels::double precision as percent, b.count * 214658.671875:: double precision as total_area,
      b.count * 214658.671875:: double precision as binary_area,
      b.count::bigint as binary_pixel_count, t.total_pixels
      FROM binary_pixels b inner join total_pixels t on b.geog_id = t.geog_id $$;

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
