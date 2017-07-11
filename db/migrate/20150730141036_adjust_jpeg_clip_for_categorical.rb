# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AdjustJpegClipForCategorical < ActiveRecord::Migration

  def change
    
    sql = <<-SQL
      CREATE OR REPLACE Function terrapop_jpeg_raster_clip_colormap_v2(sample_geog_lvl_id bigint, rasters_id bigint, raster_bnd integer, colormap text)
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
          FROM poly_table p inner join rasters r on ST_Intersects(r.rast, p.geom)
          where r.raster_variable_id = rasters_id
        )
        select ST_AsJPEG(ST_ColorMap(ST_Union(r.rast), 1, colormap), 1) as tiff from new_rast r;

        END;
      $BODY$
      LANGUAGE 'plpgsql';
    SQL
    
    sql0 = <<-SQL
      CREATE OR REPLACE Function terrapop_jpeg_raster_clip_colormap_with_buffer_v1(sample_geog_lvl_id bigint, rasters_id bigint, raster_bnd integer, colormap text)
      RETURNS TABLE (tiff bytea) AS
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
      LANGUAGE 'plpgsql';
    SQL
    
    execute sql
    
    execute sql0
    
  end
end
