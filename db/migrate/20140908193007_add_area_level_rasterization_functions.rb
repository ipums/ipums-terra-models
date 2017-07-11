# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddAreaLevelRasterizationFunctions < ActiveRecord::Migration

  def change
    
    cell_count_sql = <<-SQL_O_MATIC
    CREATE OR REPLACE Function terrapop_raster_cellcount(sample_geog_lvl_id bigint, reference_raster_variable_id bigint, raster_sizer bigint)
        Returns boolean as
            $BODY$
            DECLARE
                zero_count_geom integer;
            BEGIN
                WITH new_rast as
                (
                SELECT ST_Rescale(ST_Asraster(mybound.geom, my_rast.rast, '32BF', 1.0, -5), my_rast.scale_x/raster_sizer,
                    my_rast.scale_y/raster_sizer) as rast
                FROM     (
                    select ST_Collect(bound.geog::geometry) as geom
                    from sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                    inner join boundaries bound on bound.geog_instance_id = gi.id
                    where gi.sample_geog_level_id = sample_geog_lvl_id
                    ) mybound,
                    (
                    select ST_Scalex(r.rast) as scale_x, ST_Scaley(r.rast) as scale_y, r.rast
                    from rasters r INNER JOIN raster_variables rv ON rv.id = r.raster_variable_id
                    WHERE rv.id = reference_raster_variable_id
                    limit 1
                    ) my_rast
                )
                SELECT count(zero_geog.cell_count) into zero_count_geom
                FROM    (
                    select gi.id, gi.label,(ST_summarystats(ST_Clip(r.rast, bound.geog::geometry, True),True)).count as cell_count
                    from sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                    inner join boundaries bound on bound.geog_instance_id = gi.id
                    inner join new_rast r on ST_Intersects(r.rast,bound.geog::geometry)
                    where gi.sample_geog_level_id = sample_geog_lvl_id and (ST_summarystats(ST_Clip(r.rast, bound.geog::geometry, True),True)).count = 0
                    order by gi.id
                    ) zero_geog;

                IF zero_count_geom > 0 THEN
                    RETURN True;
                ELSE
                    RETURN FALSE;
                END IF;
            END;
            $BODY$
    LANGUAGE plpgsql;
    SQL_O_MATIC
    
    rasterization_sql = <<-SQL_O_MATIC
    CREATE OR REPLACE Function terrapop_areal_rasterization(sample_geog_lvl_id bigint, rasters_id bigint, area_data_variables_id bigint, raster_sizer bigint, bnd_num integer)
        RETURNS TABLE (rast raster)
            AS
            $BODY$
            BEGIN
                RETURN QUERY
                    WITH new_rast as
                    (
                    SELECT ST_Rescale(ST_Asraster(mybound.geom, my_rast.rast, '32BF', 1.0, -5), my_rast.scale_x/raster_sizer,
                        my_rast.scale_y/raster_sizer) as rast
                    FROM     (
                        select ST_Collect(bound.geog::geometry) as geom
                        from sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                        inner join boundaries bound on bound.geog_instance_id = gi.id
                        where gi.sample_geog_level_id = sample_geog_lvl_id
                        ) mybound,
                        (
                        select ST_Scalex(r.rast) as scale_x, ST_Scaley(r.rast) as scale_y, r.rast
                        from rasters r
                        where r.raster_variable_id = rasters_id
                        limit 1
                        ) my_rast
                    )
                   
                    SELECT ST_Union(ST_AsRaster(clip.geom, new_rast.rast, '32BF', (areal_data.value/clip.cell_count))) as rast
                    FROM new_rast,
                      (
                        select gi.id, adv.mnemonic, area_data.value
                        from sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                        inner join boundaries bound on bound.geog_instance_id = gi.id
                        left join area_data_values area_data on gi.id = area_data.geog_instance_id
                        inner join area_data_variables adv ON area_data.area_data_variable_id = adv.id
                        where gi.sample_geog_level_id = sample_geog_lvl_id and adv.id = area_data_variables_id
                      ) areal_data inner join
                      (
                        SELECT gi.id, gi.label, Sum(ST_Count(ST_Clip(r.rast, bound.geog::geometry))) as cell_count, ST_union(bound.geog::geometry) as geom
                        from sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                        inner join boundaries bound on bound.geog_instance_id = gi.id
                        inner join new_rast r on ST_Intersects(r.rast,bound.geog::geometry)
                        where gi.sample_geog_level_id = sample_geog_lvl_id
                        group by gi.id
                      ) clip on areal_data.id = clip.id;
            END;
            $BODY$
            LANGUAGE 'plpgsql';
        
    SQL_O_MATIC
    
    execute "DROP FUNCTION IF EXISTS terrapop_areal_rasterization(bigint,bigint,bigint,bigint,integer)"
    
    execute cell_count_sql
    execute rasterization_sql
    
  end
end
