# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RatioAreaLevelDataToRasterFunction < ActiveRecord::Migration

  def change
    sql =<<-SQL
    CREATE OR REPLACE Function terrapop_areal_rasterization_number(sample_geog_lvl_id bigint, rasters_id bigint, area_data_variables_id bigint, raster_sizer bigint, bnd_num integer)
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
               
                    SELECT ST_Union(ST_AsRaster(clip.geom, new_rast.rast, '32BF', areal_data.value)) as rast
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
                        SELECT gi.id, ST_union(bound.geog::geometry) as geom
                        from sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                        inner join boundaries bound on bound.geog_instance_id = gi.id
                        inner join new_rast r on ST_Intersects(r.rast, bound.geog::geometry)
                        where gi.sample_geog_level_id = sample_geog_lvl_id
                        group by gi.id
                      ) clip on areal_data.id = clip.id;
            END;
            $BODY$
            LANGUAGE 'plpgsql';
    SQL
    
    execute(sql)
    
  end
end

