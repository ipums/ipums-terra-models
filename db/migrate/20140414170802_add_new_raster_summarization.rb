# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddNewRasterSummarization < ActiveRecord::Migration

  def up
    
    summary_sql = <<-END_OF_PROC
    CREATE OR REPLACE FUNCTION terrapop_raster_summary_v4(sample_geog_lvl_id bigint, raster_var_id bigint, raster_area_var_id bigint, raster_var_ref_id bigint, raster_op_name varchar(32))
    RETURNS TABLE(sample_geog_level_id bigint, raster_variable_id bigint, raster_operation_name varchar(32), geog_instance_id bigint,
      geog_instance_label varchar(255), geog_instance_code numeric(20,0), raster_mnemonic varchar(255),
      boundary_area double precision, raster_area double precision, summary_value double precision) AS $$
    BEGIN
        RETURN QUERY
        SELECT final_last.sample_geog_level_id, final_last.raster_variable_id, final_last.raster_op_name, final_last.geog_instance_id, final_last.geog_instance_label,
               final_last.geog_instance_code, final_last.mnemonic, final_last.boundary_area, final_last.raster_area,
               terrapop_raster_summary_calc_v2(final_last.raster_op_name, final_last.rast, final_last.raster_area)::double precision as value
          FROM (SELECT final.sample_geog_level_id, final.raster_variable_id, final.raster_op_name, final.geog_instance_id,
                 final.geog_instance_label, final.geog_instance_code, final.mnemonic, final.boundary_area, final.raster_area, ST_Union(final.rast) AS rast FROM (
              select unioned_rast.sample_geog_level_id, unioned_rast.raster_variable_id, raster_op_name,
                     unioned_rast.geog_instance_id, unioned_rast.geog_instance_label, unioned_rast.geog_instance_code,
                     CAST(unioned_rast.raster_variable_name || '_' || raster_op_name as varchar(255)) as mnemonic,
                     unioned_rast.boundary_area,
                     unioned_rast.raster_area,
                     St_Union(ST_MapAlgebra(unioned_rast.rast, unioned_rast.area_rast, '([rast1] * [rast2])::float')) AS rast
                     /*ST_Union(unioned_rast.rast) AS rast*/
              from (
                select base.sample_geog_level_id, base.raster_variable_id, base.geog_instance_id, base.geog_instance_label,
                      base.geog_instance_code, base.raster_variable_name,
                      base.boundary_area::double precision AS boundary_area,
                      ST_Union(ST_MapAlgebra(area_base.rast, ST_SetGeoReference(ref_base.rast, ST_GeoReference(area_base.rast)), '([rast1] * [rast2])::float')) as area_rast,
                      ST_Union(ST_SetGeoReference(base.rast, ST_GeoReference(area_base.rast))) AS rast,
                      terrapop_raster_area_v1(base.geog_instance_id, raster_var_ref_id)::double precision AS raster_area
                from (
                  SELECT sgl.id as "sample_geog_level_id", my_raster.raster_variable_id as "raster_variable_id",
                    gi.id as "geog_instance_id", gi.label as "geog_instance_label", gi.code as "geog_instance_code",
                    my_raster.name as "raster_variable_name", ST_AREA(bound.geog) as boundary_area,
                    ST_Union(ST_Clip(my_raster.rast, bound.geog::geometry)) as rast
                  FROM sample_geog_levels sgl
                  inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                  inner join boundaries bound on bound.geog_instance_id = gi.id
                  inner join rasters my_raster on ST_Intersects(my_raster.rast, bound.geog::geometry)
                  where sgl.id = sample_geog_lvl_id and my_raster.raster_variable_id = raster_var_id
                  group by sgl.id, my_raster.raster_variable_id, gi.id, gi.label, gi.code, my_raster.name, boundary_area
                ) base,
                ( SELECT ST_Union(ST_Clip(my_raster.rast, bound.geog::geometry)) as rast
                          FROM sample_geog_levels sgl
                          inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                          inner join boundaries bound on bound.geog_instance_id = gi.id
                          inner join rasters my_raster on ST_Intersects(my_raster.rast, bound.geog::geometry)
                          where sgl.id = sample_geog_lvl_id and my_raster.raster_variable_id = raster_var_ref_id
                ) ref_base,
                ( SELECT ST_Union(ST_Clip(my_raster.rast, bound.geog::geometry)) as rast
                          FROM sample_geog_levels sgl
                          inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                          inner join boundaries bound on bound.geog_instance_id = gi.id
                          inner join rasters my_raster on ST_Intersects(my_raster.rast, bound.geog::geometry)
                          where sgl.id = sample_geog_lvl_id and my_raster.raster_variable_id = raster_area_var_id
                ) area_base
                group by base.sample_geog_level_id, base.raster_variable_id, base.geog_instance_label,
                    base.geog_instance_id, base.geog_instance_code, base.raster_variable_name,
                    base.boundary_area
              ) unioned_rast
              group by
                unioned_rast.sample_geog_level_id, unioned_rast.raster_variable_id, raster_op_name, unioned_rast.geog_instance_id, unioned_rast.geog_instance_label, unioned_rast.geog_instance_code, mnemonic, unioned_rast.boundary_area, unioned_rast.raster_area
              order by unioned_rast.geog_instance_code
            ) final
            group by final.sample_geog_level_id,
              final.raster_variable_id,
              final.raster_op_name,
              final.geog_instance_id,
              final.geog_instance_label,
              final.geog_instance_code,
              final.mnemonic,
              final.boundary_area,
              final.raster_area
            order by final.geog_instance_code
          ) final_last;
    END;
    $$ LANGUAGE plpgsql
END_OF_PROC
          
    execute summary_sql
    
  end

  def down
  end
end
