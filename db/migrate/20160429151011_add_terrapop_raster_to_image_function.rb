# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddTerrapopRasterToImageFunction < ActiveRecord::Migration

  def up
    sql =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_raster_to_image(
    IN sample_geog_lvl_id bigint[],
    IN rasters_id bigint,
    IN raster_bnd integer DEFAULT 1)
  RETURNS TABLE(img bytea) AS
    $BODY$

      DECLARE
            data_raster text := '';
            raster_type text := '';
            query text := '';

      BEGIN

      -- Every raster_variable_id goes through this query.. Determines if the raster_variable should go Categorical to Binary and go through the reclassification step

      SELECT lower(rdt.label) as raster_data_type
      into raster_type
      FROM raster_variables rv inner join raster_data_types rdt on rv.raster_data_type_id = rdt.id
      WHERE  rv.id = rasters_id;

      IF raster_type = 'binary' THEN

        WITH second_area_reference as
        (
        SELECT second_area_reference_id
        FROM new_rasters
        WHERE raster_variable_id = rasters_id
        )
        SELECT r_table_schema || '.' || table_name as table_name
        into data_raster
        FROM new_rasters inner join second_area_reference on new_rasters.raster_variable_id = second_area_reference.second_area_reference_id;

        query := $$ WITH lookup AS
        (
        SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
        FROM raster_variables WHERE id IN (
            select raster_variable_classifications.mosaic_raster_variable_id
            from raster_variable_classifications
            where raster_variable_classifications.raster_variable_id = $$ || rasters_id || $$ )
        ),projection as
        (
        SELECT ST_SRID(r.rast) as srid
        FROM $$ || data_raster || $$ r
        LIMIT 1
        ), polygon as
        (
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
        gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, prj.srid) as geom
        FROM projection prj, sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id IN ($$ || array_to_string(sample_geog_lvl_id, ',') || $$)
        )
        SELECT ST_AsTIFF(ST_Reclass(ST_Clip(r.rast, $$ || raster_bnd || $$ ,p.geom,-999, TRUE), 1, l.exp, '8BUI'), ARRAY[1], 'LZW', prj.srid ) as  img
        FROM lookup l, projection prj, polygon p inner join $$ || data_raster || $$ r on ST_Intersects(r.rast,p.geom) $$;

      ELSE

        SELECT r_table_schema || '.' || table_name as tablename
        FROM new_rasters nw
        INTO data_raster
        WHERE nw.raster_variable_id = rasters_id;

        query := $$ WITH projection as
        (
        SELECT ST_SRID(rast) as srid
        FROM $$ || data_raster || $$
        Limit 1
        ),polygon as
        (
        SELECT sgl.id as sample_geog_level_id, ST_Union(ST_Transform(bound.geog::geometry, prj.srid)) as geom
        FROM projection prj, sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id IN ($$ || array_to_string(sample_geog_lvl_id, ',') || $$)
        GROUP BY sgl.id
        ),raster_clip as
        (
        SELECT ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom,-999, False) AS rast
        FROM polygon p inner join $$ || data_raster || $$  r on ST_Intersects(r.rast,p.geom)
        )
        SELECT ST_AsTIFF(rast, ARRAY[1], 'LZW', prj.srid ) as  img
        FROM raster_clip, projection prj $$ ;

      END IF;

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

 def down
   sql =<<SQL
   DROP FUNCTION IF EXISTS terrapop_raster_to_image(bigint[], bigint, integer);
SQL
  execute(sql)
 end

end
