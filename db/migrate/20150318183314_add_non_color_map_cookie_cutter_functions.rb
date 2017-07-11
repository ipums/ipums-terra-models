# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddNonColorMapCookieCutterFunctions < ActiveRecord::Migration

  def change
    sql0 = <<-SQL
      CREATE OR REPLACE Function terrapop_jpeg_raster_clip(sample_geog_lvl_id bigint, rasters_id bigint, raster_bnd integer)
      RETURNS TABLE (tiff bytea) AS
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
        select ST_AsJPEG(ST_Union(r.rast)) as tiff from new_rast r;

        END;
      $BODY$
      LANGUAGE 'plpgsql';
    SQL
    
    sql1 = <<-SQL
      CREATE OR REPLACE Function terrapop_tiff_raster_clip(sample_geog_lvl_id bigint, rasters_id bigint, raster_bnd integer)
      RETURNS TABLE (tiff bytea) AS
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
      LANGUAGE 'plpgsql';
    SQL

    execute sql0
    execute sql1
    
  end
end
