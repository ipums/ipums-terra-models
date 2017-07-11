# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class GenericCategoricalToBinaryRasterOutputFunction < ActiveRecord::Migration

  def change
    
    sql0 =<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_categorical_to_binary_as_raster(IN sample_geog_lvl_id bigint, IN rasters_id bigint, IN bnd_num integer DEFAULT 1)
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
    LANGUAGE 'plpgsql';
    SQL
        
    execute(sql0)
    
    sql1 =<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_projection_number_from_stacked_raster(raster_id bigint)
    RETURNS integer AS
    $BODY$
      DECLARE prj_value integer;
      BEGIN
        WITH cat_rast as
        (
          SELECT rv.second_area_reference_id as cat_id
            FROM raster_variables rv
            WHERE rv.id = raster_id
        ),transformation as
        (
          SELECT ST_SRID(r.rast) AS prj_value
            FROM cat_rast c, rasters r
            WHERE r.raster_variable_id = c.cat_id 
            LIMIT 1
        )
        SELECT t.prj_value INTO prj_value FROM transformation t;
        
        RETURN prj_value;
      END;
    $BODY$
    LANGUAGE 'plpgsql';
    SQL
    
    execute(sql1)
    
    sql2 =<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_raster_as_tiff(projection integer, rast raster)
    RETURNS bytea AS
    $BODY$
    DECLARE ret_raster raster;
      BEGIN
        SELECT ST_AsTiff(rast,'LZW', projection) into ret_raster;
        RETURN ret_raster;
      END;
    $BODY$
    LANGUAGE 'plpgsql';
    SQL
    
    execute(sql2)
    
  end
end
