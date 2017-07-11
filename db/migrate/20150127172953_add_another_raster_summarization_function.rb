# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddAnotherRasterSummarizationFunction < ActiveRecord::Migration

  def change
    sql =<<-SQL
    CREATE OR REPLACE Function Terrapop_GLC_Binary_Summarization(sample_geog_lvl_id bigint, rasters_id bigint)
    RETURNS TABLE (geog_instance_id bigint, geog_instance_label character varying, binary_area double precision, total_area double precision, percent_area double precision)
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
    LANGUAGE 'plpgsql';
    SQL
    
    execute(sql)
    
  end
end
