# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RenameReturnColumnsForGliSumarization < ActiveRecord::Migration

  def change
    
    sql = <<-SQL
      CREATE OR REPLACE Function terrapop_gli_harvest_areal_summarization_v3(sample_geog_lvl_id bigint, rasters_id bigint)
      RETURNS TABLE (geog_instance_id bigint, geog_instance_label character varying, percent_area double precision, harvest_area double precision)
          AS 
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
      LANGUAGE 'plpgsql';
    SQL
   
    execute(sql)
    
  end
end
