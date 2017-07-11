# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AroundTheWorldWrapARasterFunction < ActiveRecord::Migration

  def change
    sql =<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_wrap_global_raster_v1(IN sample_geog_lvl_id bigint, IN rast_id bigint, IN rast_band_num integer)
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
        ), 
        cat_rast as
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
        gi.code as geog_instance_code, ST_Buffer(ST_Transform(bound.geog::geometry, t.prj_value), 0.0001) as geom
        FROM transformation t, sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = $$ || sample_geog_lvl_id || $$
        ), polydump as
        (
        SELECT (ST_dump(geom)).path[1] as id, (ST_dump(geom)).geom
        FROM polygon
        ), polygon_x as
        (
        Select p.id, ST_X(ST_Centroid(p.geom)) as x, p.geom
        FROM polydump p 
        ), polygon_west as
        (
        select id, x, geom
        from polygon_x
        where x > 0
        ), 
        polygon_east as
        (
        select id, x, geom
        from polygon_x
        where x < 0
        ), raster_west as
        (
        SELECT ST_union(ST_Reclass(ST_Clip(r.rast, 1,p.geom, TRUE),1,l.exp, '8BUI',0)) as rast
        FROM lookup l, polygon_west p inner join $$ || one_raster || $$ r on ST_Intersects(r.rast,p.geom)
        ), raster_east as
        (
        SELECT ST_union(ST_Reclass(ST_Clip(r.rast, 1,p.geom, TRUE),1,l.exp, '8BUI',0)) as rast
        FROM lookup l, polygon_east p inner join $$ || one_raster || $$ r on ST_Intersects(r.rast,p.geom) 
        )
        select ST_MapAlgebra(e.rast, 1, w.rast,1, '[rast1.val] + [rast2.val]' ,'32BUI', 'UNION') as rast
        from raster_east e, raster_west w $$ ;

        RAISE NOTICE  ' % ', query;

        RETURN QUERY execute query;

    END;
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100
      ROWS 1000;
    SQL
    
    execute(sql)
    
    sql1 =<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_categorical_to_binary_as_jpeg_colormap_v2(IN sample_geog_lvl_id bigint, IN rasters_id bigint, IN bnd_num integer DEFAULT 1, colormap TEXT DEFAULT 'greyscale')
    RETURNS  bytea AS
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
    LANGUAGE 'plpgsql';
    SQL
        
    execute(sql1)
  end
end
