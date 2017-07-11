# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddNewContinousSummarization < ActiveRecord::Migration

  def change
    sql =<<-SQL
      CREATE OR REPLACE Function terrapop_continuous_summarization_without_arearef(sample_geog_lvl_id bigint, rasters_id bigint, band_idx bigint)
          RETURNS TABLE (geog_instance_id bigint, geog_instance_label character varying, count bigint, total_area double precision, mean double precision, stddev double precision, min double precision, max double precision)
            AS 
            $BODY$
              BEGIN
                  RETURN QUERY
                  WITH transformation AS
                  (
                  SELECT ST_SRID(r.rast) as prj_val
                  FROM rasters r
                    WHERE r.raster_variable_id = rasters_id LIMIT 1
                  ),
                  polygon AS
                  (
                  SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, ST_Transform(bound.geog::geometry, t.prj_val) as geom
                  FROM transformation t, sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                  inner join boundaries bound on bound.geog_instance_id = gi.id
                  WHERE sgl.id = sample_geog_lvl_id
                  ),area_ref_rast as 
                  (
                  SELECT p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, ST_union(ST_Clip(r.rast, p.geom)) as rast
                  FROM polygon p inner join rasters r on ST_Intersects(r.rast, p.geom)
                  WHERE p.sample_geog_level_id = sample_geog_lvl_id and r.raster_variable_id = rasters_id
                  GROUP BY p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label
                  )
                  select a.geog_instance_id, a.geog_instance_label, (ST_Summarystats(a.rast, band_idx::integer)).*
                  from area_ref_rast a;
              END;
              $BODY$
          LANGUAGE 'plpgsql';
    SQL
    
    execute(sql)
  end
end
