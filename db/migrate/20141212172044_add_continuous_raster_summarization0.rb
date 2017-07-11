# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddContinuousRasterSummarization0 < ActiveRecord::Migration

  def change
    
    sql = <<-SQL
      CREATE OR REPLACE Function terrapop_continuous_summarization0(sample_geog_lvl_id bigint, rasters_id bigint)
        RETURNS TABLE (geog_instance_id bigint, geog_instance_label character varying, min double precision,
            max double precision, mean double precision, count bigint,stddev double precision, total_area double precision)
          AS 
          $BODY$
            BEGIN
                RETURN QUERY
                WITH
                contin_rast as 
                    (
                    SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                      gi.code as geog_instance_code, ST_Union(ST_Clip(r.rast, ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r  WHERE r.raster_variable_id = rasters_id LIMIT 1)))) as rast
                      FROM sample_geog_levels sgl
                      inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                      inner join boundaries bound on bound.geog_instance_id = gi.id
                      inner join rasters r on ST_Intersects(r.rast, ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r  WHERE r.raster_variable_id = rasters_id LIMIT 1)))
                      where sgl.id = sample_geog_lvl_id and r.raster_variable_id = rasters_id
                      group by sgl.id, gi.id, gi.label, gi.code
                    ), area_ref_rast as
                    (
                    SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
                      gi.code as geog_instance_code, ST_Union(ST_Clip(r.rast, ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r  WHERE r.raster_variable_id = rasters_id LIMIT 1)) )) as rast
                      FROM sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                      inner join boundaries bound on bound.geog_instance_id = gi.id
                      inner join rasters r on ST_Intersects(r.rast, ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r  WHERE r.raster_variable_id = rasters_id LIMIT 1)) )
                      where sgl.id = sample_geog_lvl_id and r.raster_variable_id = ( select rv.area_reference_id from raster_variables rv where rv.id = rasters_id limit 1 )
                      group by sgl.id, gi.id, gi.label, gi.code
                    )
                SELECT cont_stat.geog_instance_id::bigint, cont_stat.geog_instance_label, (cont_stat.stat).min as min, (cont_stat.stat).max as max,
                (cont_stat.stat).mean as mean, (cont_stat.stat).count as count, (cont_stat.stat).stddev as stddev, area_val.area as raster_area
                FROM    (
                    select contin_rast.geog_instance_id, contin_rast.geog_instance_label, ST_SummaryStats(contin_rast.rast) as stat
                    from contin_rast
                    ) cont_stat inner join 
                    (
                    select area_ref_rast.geog_instance_id, area_ref_rast.geog_instance_label, (ST_Summarystats(area_ref_rast.rast,1)).sum as area
                    from area_ref_rast
                    ) area_val on (cont_stat.geog_instance_id = area_val.geog_instance_id);
            END;
          $BODY$
      LANGUAGE 'plpgsql';
    SQL
    
    execute sql
    
  end
end
