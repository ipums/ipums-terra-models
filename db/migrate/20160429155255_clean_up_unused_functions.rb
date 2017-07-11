# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CleanUpUnusedFunctions < ActiveRecord::Migration

  def up
    functions_to_drop = [
      #"DROP FUNCTION terrapop_categorical_to_binary_as_tiff(bigint, bigint, integer);",
      #"DROP FUNCTION terrapop_tiff_raster_clip(bigint, bigint, integer);",
      "DROP FUNCTION terrapop_tiff_raster_clip_v2(bigint, bigint, integer);",
      "DROP FUNCTION terrapop_categorical_to_binary_as_tiff_colormap(bigint, bigint, integer, text);",
      "DROP FUNCTION terrapop_raster_clip_colormap(bigint, bigint, integer, text);",
      "DROP FUNCTION terrapop_categorical_to_binary_as_jpeg_colormap(bigint, bigint, integer, text);",
      "DROP FUNCTION terrapop_categorical_to_binary_as_jpeg_colormap_v1(bigint, bigint, integer, text);",
      "DROP FUNCTION terrapop_categorical_to_binary_as_jpeg_colormap_v2(bigint, bigint, integer, text);",
      "DROP FUNCTION terrapop_categorical_to_binary_as_raster(bigint, bigint, integer);",
      "DROP FUNCTION terrapop_categorical_to_binary_as_raster_v1(bigint, bigint, integer);",
      "DROP FUNCTION terrapop_jpeg_raster_clip_colormap(bigint, bigint, integer, text);",
      "DROP FUNCTION terrapop_jpeg_raster_clip_colormap_v2(bigint, bigint, integer, text);",
      "DROP FUNCTION terrapop_jpeg_raster_clip_colormap_with_buffer_v1(bigint, bigint, integer, text);",
      "DROP FUNCTION terrapop_reclassify_categorical_raster_to_binary_summariz_v2(bigint, bigint, integer);",
      "DROP FUNCTION terrapop_reclassify_categorical_raster_to_binary_summariz_v3(bigint, bigint, integer);",
      "DROP FUNCTION terrapop_gli_yield_areal_summarization(bigint, bigint);",
      "DROP FUNCTION terrapop_gli_harvest_areal_summarization(bigint, bigint);",
      "DROP FUNCTION terrapop_gli_harvest_areal_summarization_v2(bigint, bigint);",
      "DROP FUNCTION terrapop_gli_harvest_areal_summarization_v3(bigint, bigint);",
      "DROP FUNCTION terrapop_gli_harvest_areal_summarization_v5(bigint, bigint);",
      "DROP FUNCTION terrapop_glc_binary_summarization(bigint, bigint);",
      "DROP FUNCTION terrapop_glc_binary_summarization_v2(bigint, bigint);",
      "DROP FUNCTION terrapop_glc_binary_summarization_v3(bigint, bigint);",
      "DROP FUNCTION terrapop_glc_binary_summarization_v4(bigint, bigint);",
      "DROP FUNCTION terrapop_glc_binary_summarization_v5(bigint, bigint);",
      "DROP FUNCTION terrapop_glc_binary_summarization_v6(bigint, bigint);"
    ]
    functions_to_drop.each do |sql|
      execute(sql)
    end

  end

  def down
    sql =<<SQL
   CREATE OR REPLACE FUNCTION terrapop_categorical_to_binary_as_tiff(
    sample_geog_lvl_id bigint,
    rasters_id bigint,
    bnd_num integer DEFAULT 1)
  RETURNS bytea AS
$BODY$
      DECLARE ret_tiff bytea;
        BEGIN

        WITH lookup AS
        (
        SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
        FROM raster_variables WHERE id IN (
                select raster_variable_classifications.mosaic_raster_variable_id
                from raster_variable_classifications
                where raster_variable_classifications.raster_variable_id = rasters_id)
        ), cat_rast as
        (
        SELECT rv.second_area_reference_id as cat_id
        FROM raster_variables rv
        WHERE rv.id = rasters_id
        ),transformation as
        (
        SELECT ST_SRID(r.rast) as prj_value
        FROM cat_rast c, rasters r
        WHERE r.raster_variable_id = c.cat_id
        LIMIT 1
        ), polygon as
        (
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
        gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom
        FROM transformation t, sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = sample_geog_lvl_id
        )
        SELECT ST_AsTiff(ST_union(ST_Reclass(ST_Clip(r.rast, bnd_num,p.geom, TRUE),1,l.exp, '8BUI',0)), 'LZW', terrapop_projection_number_from_stacked_raster(rasters_id)) into ret_tiff
        FROM lookup l, cat_rast c,  polygon p inner join rasters r on ST_Intersects(r.rast,p.geom)
        WHERE r.raster_variable_id = (c.cat_id);
        RETURN ret_tiff;
        END;

        $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_tiff_raster_clip(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint,
    IN raster_bnd integer)
  RETURNS TABLE(tiff bytea) AS
$BODY$

        BEGIN
        RETURN QUERY

        WITH poly_table AS
        (
        SELECT ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = rasters_id LIMIT 1)) as geom
          FROM sample_geog_levels sgl
          inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
          inner join boundaries bound on bound.geog_instance_id = gi.id
          where gi.sample_geog_level_id = sample_geog_lvl_id
        ),
        new_rast AS
        (
          SELECT ST_Union(ST_Clip(r.rast, raster_bnd, p.geom, TRUE)) as rast
          FROM poly_table p inner join rasters r on ST_Intersects(r.rast,p.geom)
          where r.raster_variable_id = rasters_id
        )
        select ST_AsTiff(ST_Union(r.rast),'LZW', (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = rasters_id LIMIT 1)) as tiff from new_rast r;

        END;
      $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_tiff_raster_clip_v2(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint,
    IN raster_bnd integer)
  RETURNS TABLE(tiff bytea) AS
$BODY$

        BEGIN
        RETURN QUERY

        WITH poly_table AS
        (
        SELECT ST_Buffer(ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = rasters_id LIMIT 1)), 0.0000001) as geom
          FROM sample_geog_levels sgl
          inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
          inner join boundaries bound on bound.geog_instance_id = gi.id
          where gi.sample_geog_level_id = sample_geog_lvl_id
        ),
        new_rast AS
        (
          SELECT ST_Union(ST_Clip(r.rast, raster_bnd, p.geom, TRUE)) as rast
          FROM poly_table p inner join rasters r on ST_Intersects(r.rast,p.geom)
          where r.raster_variable_id = rasters_id
        )
        select ST_AsTiff(ST_Union(r.rast),'LZW', (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = rasters_id LIMIT 1)) as tiff from new_rast r;

        END;
      $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_categorical_to_binary_as_tiff_colormap(
    sample_geog_lvl_id bigint,
    rasters_id bigint,
    bnd_num integer DEFAULT 1,
    colormap text DEFAULT 'greyscale'::text)
  RETURNS bytea AS
$BODY$
      DECLARE ret_tiff bytea;
        BEGIN

        WITH lookup AS
        (
        SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
        FROM raster_variables WHERE id IN (
                select raster_variable_classifications.mosaic_raster_variable_id
                from raster_variable_classifications
                where raster_variable_classifications.raster_variable_id = rasters_id)
        ), cat_rast as
        (
        SELECT rv.second_area_reference_id as cat_id
        FROM raster_variables rv
        WHERE rv.id = rasters_id
        ),transformation as
        (
        SELECT ST_SRID(r.rast) as prj_value
        FROM cat_rast c, rasters r
        WHERE r.raster_variable_id = c.cat_id
        LIMIT 1
        ), polygon as
        (
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
        gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom
        FROM transformation t, sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = sample_geog_lvl_id
        )
        SELECT ST_AsTiff(ST_ColorMap(ST_union(ST_Reclass(ST_Clip(r.rast, bnd_num,p.geom, TRUE),1,l.exp, '8BUI',0)), 1, colormap), 'LZW', terrapop_projection_number_from_stacked_raster(rasters_id)) into ret_tiff
        FROM lookup l, cat_rast c,  polygon p inner join rasters r on ST_Intersects(r.rast,p.geom)
        WHERE r.raster_variable_id = (c.cat_id);
        RETURN ret_tiff;
        END;

        $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_raster_clip_colormap(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint,
    IN raster_bnd integer,
    IN colormap text)
  RETURNS TABLE(tiff bytea) AS
$BODY$

        BEGIN
        RETURN QUERY

        WITH poly_table AS
        (
        SELECT ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = rasters_id LIMIT 1)) as geom
          FROM sample_geog_levels sgl
          inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
          inner join boundaries bound on bound.geog_instance_id = gi.id
          where gi.sample_geog_level_id = sample_geog_lvl_id
        ),
        new_rast AS
        (
          SELECT ST_Union(ST_Clip(r.rast, raster_bnd, p.geom, TRUE)) as rast
          FROM poly_table p inner join rasters r on ST_Intersects(r.rast,p.geom)
          where r.raster_variable_id = rasters_id
        )
        select ST_AsTiff(ST_ColorMap(ST_Union(r.rast), 1, colormap),'LZW', (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = rasters_id LIMIT 1)) as tiff from new_rast r;

        END;
      $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_categorical_to_binary_as_jpeg_colormap(
    sample_geog_lvl_id bigint,
    rasters_id bigint,
    bnd_num integer DEFAULT 1,
    colormap text DEFAULT 'greyscale'::text)
  RETURNS bytea AS
$BODY$
      DECLARE ret_tiff bytea;
        BEGIN

        WITH lookup AS
        (
        SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
        FROM raster_variables WHERE id IN (
                select raster_variable_classifications.mosaic_raster_variable_id
                from raster_variable_classifications
                where raster_variable_classifications.raster_variable_id = rasters_id)
        ), cat_rast as
        (
        SELECT rv.second_area_reference_id as cat_id
        FROM raster_variables rv
        WHERE rv.id = rasters_id
        ),transformation as
        (
        SELECT ST_SRID(r.rast) as prj_value
        FROM cat_rast c, rasters r
        WHERE r.raster_variable_id = c.cat_id
        LIMIT 1
        ), polygon as
        (
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
        gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom
        FROM transformation t, sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = sample_geog_lvl_id
        )
        SELECT ST_AsJPEG(ST_union(ST_Reclass(ST_Clip(r.rast, bnd_num,p.geom, TRUE),1,l.exp, '8BUI',0)), 1) into ret_tiff
        FROM lookup l, cat_rast c,  polygon p inner join rasters r on ST_Intersects(r.rast,p.geom)
        WHERE r.raster_variable_id = (c.cat_id);
        RETURN ret_tiff;
        END;

        $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_categorical_to_binary_as_jpeg_colormap_v1(
    sample_geog_lvl_id bigint,
    rasters_id bigint,
    bnd_num integer DEFAULT 1,
    colormap text DEFAULT 'greyscale'::text)
  RETURNS bytea AS
$BODY$
      DECLARE ret_tiff bytea;
        BEGIN

        WITH lookup AS
        (
        SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
        FROM raster_variables WHERE id IN (
                select raster_variable_classifications.mosaic_raster_variable_id
                from raster_variable_classifications
                where raster_variable_classifications.raster_variable_id = rasters_id)
        ), cat_rast as
        (
        SELECT rv.second_area_reference_id as cat_id
        FROM raster_variables rv
        WHERE rv.id = rasters_id
        ),transformation as
        (
        SELECT ST_SRID(r.rast) as prj_value
        FROM cat_rast c, rasters r
        WHERE r.raster_variable_id = c.cat_id
        LIMIT 1
        ), polygon as
        (
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
        gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom
        FROM transformation t, sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = sample_geog_lvl_id
        )
        SELECT ST_AsJPEG(ST_ColorMap(ST_union(ST_Reclass(ST_Clip(r.rast, bnd_num,p.geom, TRUE),1,l.exp, '8BUI',0))), 1) into ret_tiff
        FROM lookup l, cat_rast c,  polygon p inner join rasters r on ST_Intersects(r.rast,p.geom)
        WHERE r.raster_variable_id = (c.cat_id);
        RETURN ret_tiff;
        END;

        $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
SQL
execute(sql)
    sql =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_categorical_to_binary_as_jpeg_colormap_v2(
    sample_geog_lvl_id bigint,
    rasters_id bigint,
    bnd_num integer DEFAULT 1,
    colormap text DEFAULT 'greyscale'::text)
  RETURNS bytea AS
$BODY$
      DECLARE ret_tiff bytea;
        BEGIN

        WITH lookup AS
        (
        SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
        FROM raster_variables WHERE id IN (
                select raster_variable_classifications.mosaic_raster_variable_id
                from raster_variable_classifications
                where raster_variable_classifications.raster_variable_id = rasters_id)
        ), cat_rast as
        (
        SELECT rv.second_area_reference_id as cat_id
        FROM raster_variables rv
        WHERE rv.id = rasters_id
        ),transformation as
        (
        SELECT ST_SRID(r.rast) as prj_value
        FROM cat_rast c, rasters r
        WHERE r.raster_variable_id = c.cat_id
        LIMIT 1
        ), polygon as
        (
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
        gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom
        FROM transformation t, sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = sample_geog_lvl_id
        ),
        rast_rast as
        (
          SELECT ST_union(ST_Reclass(ST_Clip(r.rast, bnd_num,p.geom, TRUE),1,l.exp, '8BUI',0)) AS rast
          FROM lookup l, cat_rast c,  polygon p inner join rasters r on ST_Intersects(r.rast,p.geom)
          WHERE r.raster_variable_id = (c.cat_id)
        ),
        rast_x as
        (
          SELECT ST_Width(rast) AS x FROM rast_rast
        ),
        rast_y as
        (
          SELECT ST_Height(rast) AS y FROM rast_rast
        )
        SELECT ST_AsJPEG(ST_ColorMap(ST_Resample(rr.rast, x.x, y.y), 1, 'fire'), 1, 100) into ret_tiff FROM rast_rast rr, rast_x x, rast_y y;
        RETURN ret_tiff;
        END;

        $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_categorical_to_binary_as_raster(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint,
    IN bnd_num integer DEFAULT 1)
  RETURNS TABLE(raster_table raster) AS
$BODY$
        BEGIN
        RETURN QUERY
        WITH lookup AS
        (
        SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
        FROM raster_variables WHERE id IN (
                select raster_variable_classifications.mosaic_raster_variable_id
                from raster_variable_classifications
                where raster_variable_classifications.raster_variable_id = rasters_id)
        ), cat_rast as
        (
        SELECT rv.second_area_reference_id as cat_id
        FROM raster_variables rv
        WHERE rv.id = rasters_id
        ),transformation as
        (
        SELECT ST_SRID(r.rast) as prj_value
        FROM cat_rast c, rasters r
        WHERE r.raster_variable_id = c.cat_id
        LIMIT 1
        ), polygon as
        (
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
        gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom
        FROM transformation t, sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = sample_geog_lvl_id
        )
        SELECT ST_union(ST_Reclass(ST_Clip(r.rast, bnd_num,p.geom, TRUE),1,l.exp, '8BUI',0)) as rast
        FROM lookup l, cat_rast c,  polygon p inner join rasters r on ST_Intersects(r.rast,p.geom)
        WHERE r.raster_variable_id = (c.cat_id);
        END;

        $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_categorical_to_binary_as_raster_v1(
    sample_geog_lvl_id bigint,
    rast_id bigint,
    rast_band_num integer)
  RETURNS SETOF raster AS
$BODY$
DECLARE

    one_raster text := 'hello';
    query text := '';

    BEGIN

    WITH lookup AS
    (
    SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
    FROM raster_variables WHERE id IN (
            select raster_variable_classifications.mosaic_raster_variable_id
            from raster_variable_classifications
            where raster_variable_classifications.raster_variable_id =  rast_id )
    ), cat_rast as
    (
    SELECT rv.second_area_reference_id as cat_id
    FROM raster_variables rv
    WHERE rv.id =  rast_id
    )
    SELECT r_table_schema || '.' || table_name as tablename
    INTO one_raster
    FROM cat_rast inner join new_rasters on cat_rast.cat_id = new_rasters.raster_variable_id ;

    RAISE NOTICE  ' % ', one_raster;

    query := $$ WITH lookup AS
    (
    SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
      FROM raster_variables WHERE id IN (
            select raster_variable_classifications.mosaic_raster_variable_id
            from raster_variable_classifications
            where raster_variable_classifications.raster_variable_id = $$ || rast_id || $$)
    )
    , transformation as
    (
    SELECT ST_SRID(r.rast) as prj_value
    FROM $$ || one_raster || $$ r
    LIMIT 1
    ), polygon as
    (
    SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
    gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom
    FROM transformation t, sample_geog_levels sgl
    inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
    inner join boundaries bound on bound.geog_instance_id = gi.id
    WHERE sgl.id = $$ || sample_geog_lvl_id || $$
    )
    SELECT ST_union(ST_Reclass(ST_Clip(r.rast, 1,p.geom, TRUE),1,l.exp, '8BUI',0)) as rast
    FROM lookup l, polygon p inner join $$ || one_raster || $$ r on ST_Intersects(r.rast,p.geom) $$ ;

    RAISE NOTICE  ' % ', query;

    RETURN QUERY execute query;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_jpeg_raster_clip_colormap(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint,
    IN raster_bnd integer,
    IN colormap text)
  RETURNS TABLE(tiff bytea) AS
$BODY$

        BEGIN
        RETURN QUERY

        WITH poly_table AS
        (
        SELECT ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = rasters_id LIMIT 1)) as geom
          FROM sample_geog_levels sgl
          inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
          inner join boundaries bound on bound.geog_instance_id = gi.id
          where gi.sample_geog_level_id = sample_geog_lvl_id
        ),
        new_rast AS
        (
          SELECT ST_Union(ST_Clip(r.rast, raster_bnd, p.geom, TRUE)) as rast
          FROM poly_table p inner join rasters r on ST_Intersects(r.rast,p.geom)
          where r.raster_variable_id = rasters_id
        )
        select ST_AsJPEG(ST_ColorMap(ST_Union(r.rast), 1, colormap), 1) as tiff from new_rast r;

        END;
      $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_jpeg_raster_clip_colormap_v2(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint,
    IN raster_bnd integer,
    IN colormap text)
  RETURNS TABLE(tiff bytea) AS
$BODY$

        BEGIN
        RETURN QUERY

        WITH poly_table AS
        (
        SELECT ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = rasters_id LIMIT 1)) as geom
          FROM sample_geog_levels sgl
          inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
          inner join boundaries bound on bound.geog_instance_id = gi.id
          where gi.sample_geog_level_id = sample_geog_lvl_id
        ),
        new_rast AS
        (
          SELECT ST_Union(ST_Clip(r.rast, raster_bnd, p.geom, TRUE)) as rast
          FROM poly_table p inner join rasters r on ST_Intersects(r.rast, p.geom)
          where r.raster_variable_id = rasters_id
        )
        select ST_AsJPEG(ST_ColorMap(ST_Union(r.rast), 1, colormap), 1) as tiff from new_rast r;

        END;
      $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_jpeg_raster_clip_colormap_with_buffer_v1(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint,
    IN raster_bnd integer,
    IN colormap text)
  RETURNS TABLE(tiff bytea) AS
$BODY$

        BEGIN
        RETURN QUERY

        WITH poly_table AS
        (
        SELECT ST_Buffer(ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = rasters_id LIMIT 1)), 0.0000001) as geom
          FROM sample_geog_levels sgl
          inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
          inner join boundaries bound on bound.geog_instance_id = gi.id
          where gi.sample_geog_level_id = sample_geog_lvl_id
        ),
        new_rast AS
        (
          SELECT ST_Union(ST_Clip(r.rast, raster_bnd, p.geom, TRUE)) as rast
          FROM poly_table p inner join rasters r on ST_Intersects(r.rast, p.geom)
          where r.raster_variable_id = rasters_id
        )
        select ST_AsJPEG(ST_ColorMap(ST_Union(r.rast), 1, colormap), 1) as tiff from new_rast r;

        END;
      $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_reclassify_categorical_raster_to_binary_summariz_v2(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint,
    IN bnd_num integer)
  RETURNS TABLE(geog_instance bigint, geog_instance_label character varying, pixel_count bigint, binary_area double precision, percent_area double precision, total_area double precision) AS
$BODY$

        BEGIN
        RETURN QUERY

        WITH lookup AS
        (
        SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
        FROM raster_variables WHERE id IN (
                select raster_variable_classifications.mosaic_raster_variable_id
                from raster_variable_classifications
                where raster_variable_classifications.raster_variable_id = rasters_id)
        ), cat_rast as
        (
        SELECT rv.area_reference_id as area_id, rv.second_area_reference_id as cat_id
        FROM raster_variables rv
        WHERE rv.id = rasters_id
        ),transformation as
        (
        SELECT ST_SRID(r.rast) as prj_value
        FROM cat_rast c, rasters r
        WHERE r.raster_variable_id = c.cat_id
        LIMIT 1
        ), polygon as
        (
        SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
        gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom, t.prj_value
        FROM transformation t, sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = sample_geog_lvl_id
        ), raster_tiles as
        (
        	SELECT rast, raster_variable_id FROM rasters r, cat_rast c WHERE r.raster_variable_id = c.cat_id
        ), r_table as
        (
        SELECT p.geog_instance_id, p.geog_instance_label, ST_Union(ST_Reclass(ST_Clip(r.rast, bnd_num, ST_Transform(p.geom, p.prj_value), TRUE),1,l.exp, '8BUI',0)) as rast
        FROM lookup l, cat_rast c, polygon p inner join raster_tiles r on ST_Intersects(r.rast, ST_Transform(p.geom, p.prj_value))
        WHERE r.raster_variable_id = (c.cat_id)
        GROUP by p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
        ), a_table as
        (
        SELECT p.geog_instance_id, p.geog_instance_label, ST_union(ST_Clip(r.rast, ST_Transform(p.geom, p.prj_value))) as rast
        FROM lookup l, cat_rast c, polygon p inner join raster_tiles r on ST_Intersects(r.rast, ST_Transform(p.geom, p.prj_value))
        WHERE r.raster_variable_id = (c.area_id)
        GROUP by p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
        ), calc as
        (
        SELECT r.geog_instance_id, r.geog_instance_label, (ST_SummaryStats(r.rast)).*, (ST_SummaryStats(a.rast)).sum as total_area,
        (ST_SummaryStats(ST_MapAlgebra(r.rast, 1, a.rast, 1, '[rast1]*[rast2]', '32BUI'))).sum as binary_area
        FROM r_table r inner join a_table a on (r.geog_instance_id = a.geog_instance_id)
        )
        SELECT c.geog_instance_id, c.geog_instance_label, c.count as pixel_count, c.binary_area,
        c.binary_area / c.total_area as percent_area, c.total_area as total_area
        FROM calc c;

        END;

        $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_reclassify_categorical_raster_to_binary_summariz_v3(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint,
    IN bnd_num integer)
  RETURNS TABLE(geog_instance bigint, geog_instance_label character varying, pixel_count bigint, binary_area double precision, percent_area double precision, total_area double precision) AS
$BODY$

    DECLARE
        area_raster_id integer;
        categorical_raster_id integer;

    BEGIN
        SELECT rv.area_reference_id as area_id into area_raster_id FROM raster_variables rv WHERE rv.id =  rasters_id ;
        SELECT rv.second_area_reference_id into categorical_raster_id FROM raster_variables rv WHERE rv.id = rasters_id ;

        RETURN QUERY

        WITH lookup AS
            (
            SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
            FROM raster_variables WHERE id IN (
                    select raster_variable_classifications.mosaic_raster_variable_id
                    from raster_variable_classifications
                    where raster_variable_classifications.raster_variable_id = rasters_id)
            ), transformation as
            (
            SELECT ST_SRID(r.rast) as prj_value
            FROM rasters r
            WHERE r.raster_variable_id = categorical_raster_id
            LIMIT 1
            ), polygon as
            (
            SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
            gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom
            FROM transformation t, sample_geog_levels sgl
            inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
            inner join boundaries bound on bound.geog_instance_id = gi.id
            WHERE sgl.id = sample_geog_lvl_id
            ), r_table as
            (
            SELECT p.geog_instance_id, p.geog_instance_label, ST_union(ST_Reclass(ST_Clip(r.rast, bnd_num ,p.geom, TRUE),1,l.exp, '8BUI',0)) as rast
            FROM lookup l, polygon p inner join rasters r on ST_Intersects(r.rast, p.geom)
            WHERE r.raster_variable_id = categorical_raster_id
            GROUP by p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
            ), a_table as
            (
            SELECT p.geog_instance_id, p.geog_instance_label, ST_union(ST_Clip(r.rast, p.geom)) as rast
            FROM lookup l, polygon p inner join rasters r on ST_Intersects(r.rast, p.geom)
            WHERE r.raster_variable_id = area_raster_id
            GROUP by p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
            ), calc as
            (
            SELECT r.geog_instance_id, r.geog_instance_label, (ST_SummaryStats(r.rast)).*, (ST_SummaryStats(a.rast)).sum as total_area,
            (ST_SummaryStats(ST_MapAlgebra(r.rast, 1, a.rast, 1, '[rast1]*[rast2]', '32BUI'))).sum as binary_area
            FROM r_table r inner join a_table a on (r.geog_instance_id = a.geog_instance_id)
            )
            SELECT c.geog_instance_id, c.geog_instance_label, c.count as pixel_count, c.binary_area,
            c.binary_area / c.total_area as percent_area, c.total_area as total_area
            FROM calc c;

    END;
    $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_gli_yield_areal_summarization(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint)
  RETURNS TABLE(geog_instance bigint, geog_instance_label character varying, min double precision, max double precision, mean double precision, count bigint) AS
$BODY$
          BEGIN
              RETURN QUERY
                  WITH bin_rast as
                  (
                  SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                  gi.code as geog_instance_code, ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast
                  FROM sample_geog_levels sgl
                  inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                  inner join boundaries bound on bound.geog_instance_id = gi.id
                  inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
                  where sgl.id = sample_geog_lvl_id and r.raster_variable_id = rasters_id
                  group by sgl.id, gi.id, gi.label, gi.code
                  ), area_ref_rast as
                  (
                  SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                  gi.code as geog_instance_code,ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast
                  FROM sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                  inner join boundaries bound on bound.geog_instance_id = gi.id
                  inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
                  where sgl.id = sample_geog_lvl_id and r.raster_variable_id = ( select rv.area_reference_id from raster_variables rv where rv.id = rasters_id limit 1 )
                  group by sgl.id, gi.id, gi.label, gi.code
                  )
                  SELECT bin_rast.geog_instance_id, bin_rast.geog_instance_label,
                  sum((ST_SummaryStats(bin_rast.rast,1)).min) as min,
                  sum((ST_SummaryStats(bin_rast.rast,1)).max) as max,
                  sum((ST_SummaryStats(bin_rast.rast,1)).mean) as mean,
                  sum((ST_SummaryStats(bin_rast.rast,1)).count)::bigint as yield_cell_count
                  FROM bin_rast inner join area_ref_rast on ST_intersects(bin_rast.rast, area_ref_rast.rast)
                  GROUP BY bin_rast.geog_instance_id, bin_rast.geog_instance_label;
          END;
          $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_gli_harvest_areal_summarization(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint)
  RETURNS TABLE(geog_instance bigint, geog_instance_label character varying, percent_area double precision, harvest_area double precision) AS
$BODY$
          BEGIN
              RETURN QUERY
                  WITH bin_rast as
                      (
                      SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                      gi.code as geog_instance_code, ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast
                      FROM sample_geog_levels sgl
                      inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                      inner join boundaries bound on bound.geog_instance_id = gi.id
                      inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
                      where sgl.id = sample_geog_lvl_id and r.raster_variable_id = rasters_id
                      group by sgl.id, gi.id, gi.label, gi.code
                      ), zero_rast as
                      (
                      SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                      gi.code as geog_instance_code,
                      ST_Union(ST_Clip(ST_SetBandNoDataValue(r.rast,0), bound.geog::geometry)) as rast
                      FROM sample_geog_levels sgl
                      inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                      inner join boundaries bound on bound.geog_instance_id = gi.id
                      inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
                      where sgl.id = sample_geog_lvl_id and r.raster_variable_id = rasters_id
                      group by sgl.id, gi.id, gi.label, gi.code
                      ), area_ref_rast as
                      (
                      SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                      gi.code as geog_instance_code,ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast , sum((ST_SummaryStats(r.rast)).sum) as total_area
                      FROM sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                      inner join boundaries bound on bound.geog_instance_id = gi.id
                      inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
                      where sgl.id = sample_geog_lvl_id and r.raster_variable_id = ( select rv.area_reference_id from raster_variables rv where rv.id = rasters_id limit 1 )
                      group by sgl.id, gi.id, gi.label, gi.code
                      ), final_rast as
                      (
                      SELECT bin_rast.geog_instance_id, bin_rast.geog_instance_label,
                      sum((ST_SummaryStats(ST_Intersection(ST_Intersection(bin_rast.rast,zero_rast.rast),area_ref_rast.rast,'band2'),1)).sum) as harvest_area
                      FROM zero_rast inner join bin_rast on bin_rast.geog_instance_id = zero_rast.geog_instance_id
                      inner join area_ref_rast on bin_rast.geog_instance_id = area_ref_rast.geog_instance_id
                      GROUP BY bin_rast.geog_instance_id, bin_rast.geog_instance_label
                      )
                      select f.geog_instance_id, f.geog_instance_label, (f.harvest_area/a.total_area) as percent_area, f.harvest_area
                      from final_rast f inner join area_ref_rast a on f.geog_instance_id = a.geog_instance_id;
          END;
          $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_gli_harvest_areal_summarization_v2(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint)
  RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, percent double precision, harvest_area double precision) AS
$BODY$
          BEGIN
              RETURN QUERY
                  WITH bin_rast as
                      (
                      SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                      gi.code as geog_instance_code, ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast
                      FROM sample_geog_levels sgl
                      inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                      inner join boundaries bound on bound.geog_instance_id = gi.id
                      inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
                      where sgl.id = sample_geog_lvl_id and r.raster_variable_id = rasters_id
                      group by sgl.id, gi.id, gi.label, gi.code
                      ), zero_rast as
                      (
                      SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                      gi.code as geog_instance_code,
                      ST_Union(ST_Clip(ST_SetBandNoDataValue(r.rast,0), bound.geog::geometry)) as rast
                      FROM sample_geog_levels sgl
                      inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                      inner join boundaries bound on bound.geog_instance_id = gi.id
                      inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
                      where sgl.id = sample_geog_lvl_id and r.raster_variable_id = rasters_id
                      group by sgl.id, gi.id, gi.label, gi.code
                      ), area_ref_rast as
                      (
                      SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                      gi.code as geog_instance_code,ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast , sum((ST_SummaryStats(r.rast)).sum) as total_area
                      FROM sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                      inner join boundaries bound on bound.geog_instance_id = gi.id
                      inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
                      where sgl.id = sample_geog_lvl_id and r.raster_variable_id = ( select rv.area_reference_id from raster_variables rv where rv.id = rasters_id limit 1 )
                      group by sgl.id, gi.id, gi.label, gi.code
                      ), final_rast as
                      (
                      SELECT bin_rast.geog_instance_id, bin_rast.geog_instance_label,
                      sum((ST_SummaryStats(ST_Intersection(ST_Intersection(bin_rast.rast,zero_rast.rast),area_ref_rast.rast,'band2'),1)).sum) as harvest_area
                      FROM zero_rast inner join bin_rast on bin_rast.geog_instance_id = zero_rast.geog_instance_id
                      inner join area_ref_rast on bin_rast.geog_instance_id = area_ref_rast.geog_instance_id
                      GROUP BY bin_rast.geog_instance_id, bin_rast.geog_instance_label
                      )
                      select f.geog_instance_id, f.geog_instance_label, (f.harvest_area/a.total_area) as percent_area, f.harvest_area
                      from final_rast f inner join area_ref_rast a on f.geog_instance_id = a.geog_instance_id;
          END;
          $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_gli_harvest_areal_summarization_v3(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint)
  RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, percent_area double precision, harvest_area double precision) AS
$BODY$
          BEGIN
              RETURN QUERY
                  WITH bin_rast as
                      (
                      SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                      gi.code as geog_instance_code, ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast
                      FROM sample_geog_levels sgl
                      inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                      inner join boundaries bound on bound.geog_instance_id = gi.id
                      inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
                      where sgl.id = sample_geog_lvl_id and r.raster_variable_id = rasters_id
                      group by sgl.id, gi.id, gi.label, gi.code
                      ), zero_rast as
                      (
                      SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                      gi.code as geog_instance_code,
                      ST_Union(ST_Clip(ST_SetBandNoDataValue(r.rast,0), bound.geog::geometry)) as rast
                      FROM sample_geog_levels sgl
                      inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                      inner join boundaries bound on bound.geog_instance_id = gi.id
                      inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
                      where sgl.id = sample_geog_lvl_id and r.raster_variable_id = rasters_id
                      group by sgl.id, gi.id, gi.label, gi.code
                      ), area_ref_rast as
                      (
                      SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                      gi.code as geog_instance_code,ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast , sum((ST_SummaryStats(r.rast)).sum) as total_area
                      FROM sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                      inner join boundaries bound on bound.geog_instance_id = gi.id
                      inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
                      where sgl.id = sample_geog_lvl_id and r.raster_variable_id = ( select rv.area_reference_id from raster_variables rv where rv.id = rasters_id limit 1 )
                      group by sgl.id, gi.id, gi.label, gi.code
                      ), final_rast as
                      (
                      SELECT bin_rast.geog_instance_id, bin_rast.geog_instance_label,
                      sum((ST_SummaryStats(ST_Intersection(ST_Intersection(bin_rast.rast,zero_rast.rast),area_ref_rast.rast,'band2'),1)).sum) as harvest_area
                      FROM zero_rast inner join bin_rast on bin_rast.geog_instance_id = zero_rast.geog_instance_id
                      inner join area_ref_rast on bin_rast.geog_instance_id = area_ref_rast.geog_instance_id
                      GROUP BY bin_rast.geog_instance_id, bin_rast.geog_instance_label
                      )
                      select f.geog_instance_id, f.geog_instance_label, (f.harvest_area/a.total_area) as percent_area, f.harvest_area
                      from final_rast f inner join area_ref_rast a on f.geog_instance_id = a.geog_instance_id;
          END;
          $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_gli_harvest_areal_summarization_v5(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint)
  RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, geog_instance_code numeric, percent_area double precision, harvested_area double precision, total_area double precision) AS
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
        SELECT s.gid, s.label, s.geog_instance_code, (s.hectar_area/s.total_area) as percent_area, s.hectar_area as harvested_area, s.total_area
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
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_glc_binary_summarization(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint)
  RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, binary_area double precision, total_area double precision, percent_area double precision) AS
$BODY$
        BEGIN
        RETURN QUERY
            WITH bin_rast as
            (
            SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
            gi.code as geog_instance_code, ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast
            FROM sample_geog_levels sgl
            inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
            inner join boundaries bound on bound.geog_instance_id = gi.id
            inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
            where sgl.id = sample_geog_lvl_id and r.raster_variable_id = rasters_id
            group by sgl.id, gi.id, gi.label, gi.code
            ), area_ref_rast as
            (
            SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
            gi.code as geog_instance_code, ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast
            FROM sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
            inner join boundaries bound on bound.geog_instance_id = gi.id
            inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
            where sgl.id = sample_geog_lvl_id and r.raster_variable_id = ( select rv.area_reference_id from raster_variables rv where rv.id = rasters_id limit 1)
            group by sgl.id, gi.id, gi.label, gi.code
            )
            SELECT bin_rast.geog_instance_id, bin_rast.geog_instance_label, sum((ST_SummaryStats(ST_Intersection(bin_rast.rast,area_ref_rast.rast,'band2'),1)).sum) as binary_area,
            sum((ST_SummaryStats(area_ref_rast.rast)).sum) as total_area,
            sum((ST_SummaryStats(ST_Intersection(bin_rast.rast,area_ref_rast.rast,'band2'),1)).sum) / sum((ST_SummaryStats(area_ref_rast.rast)).sum) as percent_area
            FROM bin_rast inner join area_ref_rast on ST_intersects(bin_rast.rast, area_ref_rast.rast)
            GROUP BY bin_rast.geog_instance_id, bin_rast.geog_instance_label;

        END;
        $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL

CREATE OR REPLACE FUNCTION terrapop_glc_binary_summarization_v2(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint)
  RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, binary_area double precision, total_area double precision, percent_area double precision) AS
$BODY$
        BEGIN
        RETURN QUERY
            WITH bin_rast as
            (
            SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
            gi.code as geog_instance_code, ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast
            FROM sample_geog_levels sgl
            inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
            inner join boundaries bound on bound.geog_instance_id = gi.id
            inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
            where sgl.id = sample_geog_lvl_id and r.raster_variable_id = rasters_id
            group by sgl.id, gi.id, gi.label, gi.code
            ), area_ref_rast as
            (
            SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
            gi.code as geog_instance_code, ST_Union(ST_Clip(r.rast, bound.geog::geometry)) as rast
            FROM sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
            inner join boundaries bound on bound.geog_instance_id = gi.id
            inner join rasters r on ST_Intersects(r.rast,bound.geog::geometry)
            where sgl.id = sample_geog_lvl_id and r.raster_variable_id = ( select rv.area_reference_id from raster_variables rv where rv.id = rasters_id limit 1)
            group by sgl.id, gi.id, gi.label, gi.code
            )
            SELECT b.geog_instance_id, b.geog_instance_label, (ST_SummaryStats(ST_MapAlgebra(b.rast, 1, a.rast, 1, '[rast1]*[rast2]'))).sum as binary_area,
            (ST_SummaryStats(a.rast)).sum as total_area, ( (ST_SummaryStats(ST_MapAlgebra(b.rast, 1, a.rast, 1, '[rast1]*[rast2]'))).sum / (ST_SummaryStats(a.rast)).sum ) as percent_area
            FROM bin_rast b inner join area_ref_rast a on b.geog_instance_id = a.geog_instance_id;

        END;
        $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_glc_binary_summarization_v3(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint)
  RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, binary_area double precision, total_area double precision, percent_area double precision) AS
$BODY$
            BEGIN
            RETURN QUERY
    		with bounds as
    		(
    			SELECT sgl.id as sample_geog_level_id, gi.id as gid, gi.label as label, gi.code as geog_instance_code, bound.geog::geometry as geom
    			FROM sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id inner join boundaries bound on bound.geog_instance_id = gi.id
    			where sgl.id = sample_geog_lvl_id group by sgl.id, gi.id, gi.label, gi.code, bound.geog
    		),

    		bin_rast as
    		(
    			SELECT b.gid as gid, b.label as label, ST_Union(ST_Clip(r.rast, b.geom)) as rast
    			FROM bounds b inner join rasters r on ST_Intersects(r.rast, b.geom)
    			where r.raster_variable_id = rasters_id group by b.gid, b.label
    		),

    		area_reference_id as (select rv.area_reference_id as id from raster_variables rv where rv.id = rasters_id limit 1),

    		area_ref_rast as
    		(
    			SELECT b.gid as gid, b.label as label, ST_Union(ST_Clip(r.rast, b.geom)) as rast
    			FROM area_reference_id a, bounds b inner join rasters r on ST_Intersects(r.rast, b.geom)
    			where r.raster_variable_id = a.id group by b.gid, b.label
    		),


    		binary_area as
    		(
    			select b.gid, b.label, (ST_SummaryStats(ST_MapAlgebra(b.rast, 1, a.rast, 1, '[rast1]*[rast2]'))).sum as binary_area
    			FROM bin_rast b inner join area_ref_rast a on b.gid = a.gid
    			group by b.gid, b.label, a.rast, b.rast
    		),

    		total_area as
    		(
    			SELECT a.gid as gid, a.label as label, (ST_SummaryStats(a.rast, true)).sum as total_area
    			FROM area_ref_rast a group by a.gid, a.label, a.rast order by a.label
    		),

    		percent_area as
    		(
    			select a.gid as gid, a.label as label, a.binary_area/b.total_area as percent_area
    			from binary_area a, total_area b where a.gid = b.gid order by a.label
    		)

    		SELECT b.gid, b.label, b.binary_area, t.total_area, p.percent_area
    		FROM binary_area b inner join total_area t on b.gid = t.gid inner join percent_area p on t.gid = p.gid;

            END;
            $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_glc_binary_summarization_v4(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint)
  RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, binary_area double precision, total_area double precision, percent_area double precision) AS
$BODY$
            BEGIN
            RETURN QUERY
        WITH srid as

        (

        	SELECT st_srid(r.rast) as srid FROM rasters r

        	where r.raster_variable_id = rasters_id

        	limit 1

        ),

       bounds as
        (

        	SELECT sgl.id as sample_geog_level_id, gi.id as gid, gi.label as label, gi.code as geog_instance_code, st_transform(bound.geog::geometry, srid.srid) as geom

        	FROM srid, sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id inner join boundaries bound on bound.geog_instance_id = gi.id

        	where sgl.id = sample_geog_lvl_id group by sgl.id, gi.id, gi.label, gi.code, bound.geog

        ),

    		bin_rast as
    		(
    			SELECT b.gid as gid, b.label as label, ST_Union(ST_Clip(r.rast, b.geom)) as rast
    			FROM bounds b inner join rasters r on ST_Intersects(r.rast, b.geom)
    			where r.raster_variable_id = rasters_id group by b.gid, b.label
    		),

    		area_reference_id as (select rv.area_reference_id as id from raster_variables rv where rv.id = rasters_id limit 1),

    		area_ref_rast as
    		(
    			SELECT b.gid as gid, b.label as label, ST_Union(ST_Clip(r.rast, b.geom)) as rast
    			FROM area_reference_id a, bounds b inner join rasters r on ST_Intersects(r.rast, b.geom)
    			where r.raster_variable_id = a.id group by b.gid, b.label
    		),

    		binary_area as
    		(
    			select b.gid, b.label, (ST_SummaryStats(ST_MapAlgebra(b.rast, 1, a.rast, 1, '[rast1]*[rast2]'))).sum as binary_area
    			FROM bin_rast b inner join area_ref_rast a on b.gid = a.gid
    			group by b.gid, b.label, a.rast, b.rast
    		),

    		total_area as
    		(
    			SELECT a.gid as gid, a.label as label, (ST_SummaryStats(a.rast, true)).sum as total_area
    			FROM area_ref_rast a group by a.gid, a.label, a.rast order by a.label
    		),

    		percent_area as
    		(
    			select a.gid as gid, a.label as label, a.binary_area/b.total_area as percent_area
    			from binary_area a, total_area b where a.gid = b.gid order by a.label
    		)

    		SELECT b.gid, b.label, b.binary_area, t.total_area, p.percent_area
    		FROM binary_area b inner join total_area t on b.gid = t.gid inner join percent_area p on t.gid = p.gid;

            END;
            $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_glc_binary_summarization_v5(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint)
  RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, binary_area double precision, total_area double precision, percent_area double precision) AS
$BODY$
            BEGIN
            RETURN QUERY
        WITH srid as

        (

        	SELECT st_srid(r.rast) as srid FROM rasters r

        	where r.raster_variable_id = rasters_id

        	limit 1

        ),

       bounds as
        (

        	SELECT sgl.id as sample_geog_level_id, gi.id as gid, gi.label as label, gi.code as geog_instance_code, st_transform(bound.geog::geometry, srid.srid) as geom

        	FROM srid, sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id inner join boundaries bound on bound.geog_instance_id = gi.id

        	where sgl.id = sample_geog_lvl_id group by sgl.id, gi.id, gi.label, gi.code, bound.geog, srid.srid

        ),

    		bin_rast as
    		(
    			SELECT b.gid as gid, b.label as label, ST_Union(ST_Clip(r.rast, b.geom)) as rast
    			FROM bounds b inner join rasters r on ST_Intersects(r.rast, b.geom)
    			where r.raster_variable_id = rasters_id group by b.gid, b.label
    		),

    		area_reference_id as (select rv.area_reference_id as id from raster_variables rv where rv.id = rasters_id limit 1),

    		area_ref_rast as
    		(
    			SELECT b.gid as gid, b.label as label, ST_Union(ST_Clip(r.rast, b.geom)) as rast
    			FROM area_reference_id a, bounds b inner join rasters r on ST_Intersects(r.rast, b.geom)
    			where r.raster_variable_id = a.id group by b.gid, b.label
    		),

    		binary_area as
    		(
    			select b.gid, b.label, (ST_SummaryStats(ST_MapAlgebra(b.rast, 1, a.rast, 1, '[rast1]*[rast2]'))).sum as binary_area
    			FROM bin_rast b inner join area_ref_rast a on b.gid = a.gid
    			group by b.gid, b.label, a.rast, b.rast
    		),

    		total_area as
    		(
    			SELECT a.gid as gid, a.label as label, (ST_SummaryStats(a.rast, true)).sum as total_area
    			FROM area_ref_rast a group by a.gid, a.label, a.rast order by a.label
    		),

    		percent_area as
    		(
    			select a.gid as gid, a.label as label, a.binary_area/b.total_area as percent_area
    			from binary_area a, total_area b where a.gid = b.gid order by a.label
    		)

    		SELECT b.gid, b.label, b.binary_area, t.total_area, p.percent_area
    		FROM binary_area b inner join total_area t on b.gid = t.gid inner join percent_area p on t.gid = p.gid;

            END;
            $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
    sql =<<SQL
CREATE OR REPLACE FUNCTION terrapop_glc_binary_summarization_v6(
    IN sample_geog_lvl_id bigint,
    IN rasters_id bigint)
  RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, binary_area double precision, total_area double precision, percent_area double precision) AS
$BODY$
          BEGIN
          RETURN QUERY
      WITH srid as

      (

      	SELECT st_srid(r.rast) as srid FROM rasters r

      	where r.raster_variable_id = rasters_id

      	limit 1

      ),
      only_rasters AS
      (
        SELECT id, raster_variable_id, rast FROM rasters WHERE raster_variable_id = rasters_id
      ),
      bounds as
      (

      	SELECT sgl.id as sample_geog_level_id, gi.id as gid, gi.label as label, gi.code as geog_instance_code, st_transform(bound.geog::geometry, srid.srid) as geom

      	FROM srid, sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id inner join boundaries bound on bound.geog_instance_id = gi.id

      	where sgl.id = sample_geog_lvl_id group by sgl.id, gi.id, gi.label, gi.code, bound.geog, srid.srid

      ),

  		bin_rast as
  		(
  			SELECT b.gid as gid, b.label as label, ST_Union(ST_Clip(r.rast, b.geom)) as rast
  			FROM bounds b inner join only_rasters r on ST_Intersects(r.rast, b.geom)
  			where r.raster_variable_id = rasters_id group by b.gid, b.label
  		),

  		area_reference_id as (select rv.area_reference_id as id from raster_variables rv where rv.id = rasters_id limit 1),

  		area_ref_rast as
  		(
  			SELECT b.gid as gid, b.label as label, ST_Union(ST_Clip(r.rast, b.geom)) as rast
  			FROM area_reference_id a, bounds b inner join only_rasters r on ST_Intersects(r.rast, b.geom)
  			where r.raster_variable_id = a.id group by b.gid, b.label
  		),

  		binary_area as
  		(
  			select b.gid, b.label, (ST_SummaryStats(ST_MapAlgebra(b.rast, 1, a.rast, 1, '[rast1]*[rast2]'))).sum as binary_area
  			FROM bin_rast b inner join area_ref_rast a on b.gid = a.gid
  			group by b.gid, b.label, a.rast, b.rast
  		),

  		total_area as
  		(
  			SELECT a.gid as gid, a.label as label, (ST_SummaryStats(a.rast, true)).sum as total_area
  			FROM area_ref_rast a group by a.gid, a.label, a.rast order by a.label
  		),

  		percent_area as
  		(
  			select a.gid as gid, a.label as label, a.binary_area/b.total_area as percent_area
  			from binary_area a, total_area b where a.gid = b.gid order by a.label
  		)

  		SELECT b.gid, b.label, b.binary_area, t.total_area, p.percent_area
  		FROM binary_area b inner join total_area t on b.gid = t.gid inner join percent_area p on t.gid = p.gid;

          END;
          $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
SQL
execute(sql)
  end
end
