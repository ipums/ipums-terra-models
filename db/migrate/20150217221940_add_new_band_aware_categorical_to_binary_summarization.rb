# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddNewBandAwareCategoricalToBinarySummarization < ActiveRecord::Migration

  def change
    
    sql0 =<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_reclassify_categorical_raster_to_binary_summarization(IN smpl_geog_lvl_id integer, rast_var_id integer, band_num integer DEFAULT 1)
      RETURNS TABLE("sample_geog_level_id" bigint, "geog_instance_label" character varying, "geog_instance_id" bigint, "reclass_pix" bigint, "area_pix" bigint, "percent_area" float, "reclass_area" float) AS
      $BODY$
        BEGIN
          RETURN QUERY
            WITH lookup AS
            (
            SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
              FROM raster_variables WHERE id IN (
                select raster_variable_classifications.mosaic_raster_variable_id 
                from raster_variable_classifications
                where raster_variable_classifications.raster_variable_id = rast_var_id)
            ), categorical_rast AS
            (
            SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, ST_union(ST_Clip(r.rast, band_num, ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = (select rv.second_area_reference_id from raster_variables rv where rv.id = rast_var_id limit 1) LIMIT 1)), TRUE)) as rast
            FROM sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
            inner join boundaries bound on bound.geog_instance_id = gi.id
            inner join rasters r on ST_Intersects(r.rast, ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = (select rv.second_area_reference_id from raster_variables rv where rv.id = rast_var_id limit 1) LIMIT 1)))
            WHERE sgl.id = smpl_geog_lvl_id and r.raster_variable_id = (select rv.second_area_reference_id from raster_variables rv where rv.id = rast_var_id limit 1)
            GROUP by sgl.id, gi.id, gi.label, gi.code
            ), area_rast AS
            (
            SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, ST_union(ST_Clip(r.rast, ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = (select rv.area_reference_id from raster_variables rv where rv.id = rast_var_id limit 1) LIMIT 1)))) as rast
            FROM sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
            inner join boundaries bound on bound.geog_instance_id = gi.id
            inner join rasters r on ST_Intersects(r.rast, ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = (select rv.area_reference_id from raster_variables rv where rv.id = rast_var_id limit 1) LIMIT 1)))
            WHERE sgl.id = smpl_geog_lvl_id and r.raster_variable_id = (select rv.area_reference_id from raster_variables rv where rv.id = rast_var_id limit 1)
            GROUP by sgl.id, gi.id, gi.label, gi.code
            ), rast_data AS
            (
            SELECT a.sample_geog_level_id, reclass.geog_instance_label, reclass.geog_instance_id,
            (ST_SummaryStats(ST_Intersection(reclass.rast, a.rast, 'band2', 0))).sum as reclass_area, (ST_SummaryStats(a.rast)).sum as unit_area
            , ST_Count(reclass.rast) as reclass_pix, ST_Count(a.rast) as area_pix
            FROM    (
              select r.geog_instance_label, r.geog_instance_id, ST_Reclass(r.rast, 1, l.exp, '8BUI', 0) as rast
              from categorical_rast r, lookup l
              )reclass inner join area_rast a on (reclass.geog_instance_id = a.geog_instance_id)
            )
            SELECT r.sample_geog_level_id, r.geog_instance_label, r.geog_instance_id, r.reclass_pix, r.area_pix, (r.reclass_area/r.unit_area)*100 as percent_area, r.reclass_area as reclass_area
            FROM rast_data r;

        END;
      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100
      ROWS 1000;
    SQL
    
    sql1 =<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_reclassify_categorical_raster_to_binary_summarization(IN smpl_geog_lvl_id integer, rast_var_id integer, band_num integer DEFAULT 1)
          RETURNS TABLE("sample_geog_level_id" bigint, "geog_instance_label" character varying, "geog_instance_id" bigint, "reclass_pix" bigint, "area_pix" bigint, "percent_area" float, "reclass_area" float) AS
          $BODY$
            BEGIN
              RETURN QUERY

                WITH lookup AS
                (
                SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
                FROM raster_variables WHERE id IN (
                        select raster_variable_classifications.mosaic_raster_variable_id 
                        from raster_variable_classifications
                        where raster_variable_classifications.raster_variable_id = rast_var_id)
                ), transformation AS 
                (
                SELECT ST_SRID(r.rast) as prj_val
                FROM rasters r
                WHERE r.raster_variable_id = (select rv.second_area_reference_id from raster_variables rv where rv.id = rast_var_id limit 1) LIMIT 1
                ), polygon AS
                (
                SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, ST_Transform(bound.geog::geometry, t.prj_val) as geom
                FROM transformation t, sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
                inner join boundaries bound on bound.geog_instance_id = gi.id
                WHERE sgl.id = smpl_geog_lvl_id
                ), categorical_rast AS
                (
                SELECT p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, ST_union(ST_Clip(r.rast, band_num, p.geom, 0, True)) as rast
                FROM polygon p inner join rasters r on ST_Intersects(r.rast, band_num, p.geom)
                WHERE r.raster_variable_id = (select rv.second_area_reference_id from raster_variables rv where rv.id = rast_var_id limit 1)
                GROUP BY p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label
                ),reclass_rast AS
                (
                select r.sample_geog_level_id, r.geog_instance_id, r.geog_instance_label, ST_Reclass(r.rast, 1, l.exp, '8BUI', 0) as rast
                from categorical_rast r, lookup l
                ), area_rast AS
                (
                SELECT p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, ST_union(ST_Clip(r.rast, 1, p.geom, 0, True)) as rast
                FROM polygon p inner join rasters r on ST_Intersects(r.rast, 1, p.geom)
                WHERE r.raster_variable_id = (select rv.area_reference_id from raster_variables rv where rv.id = rast_var_id limit 1)
                GROUP BY p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label
                ), calc AS
                (
                SELECT r.sample_geog_level_id, r.geog_instance_label, r.geog_instance_id, (ST_SummaryStats(ST_MapAlgebra(r.rast, 1, a.rast, 1, '[rast1]*[rast2]' ,'32BUI'))).sum as binary_area,
                (ST_SummaryStats(a.rast)).sum as unit_area, ST_Count(r.rast) as reclass_pix, ST_Count(a.rast) as area_pix
                FROM area_rast a inner join reclass_rast r on a.geog_instance_id = r.geog_instance_id
                )
                SELECT c.sample_geog_level_id, c.geog_instance_label, c.geog_instance_id, c.reclass_pix, c.area_pix, c.binary_area/c.unit_area as percent_area, c.binary_area as reclass_area
                FROM calc c;
            END;
          $BODY$
          LANGUAGE plpgsql VOLATILE
          COST 100
          ROWS 1000;
    SQL
    
    sql =<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_reclassify_categorical_raster_to_binary_summarization(IN sample_geog_lvl_id bigint, IN rasters_id bigint, IN bnd_num integer)
    RETURNS TABLE(geog_instance bigint, geog_instance_label character varying, pixel_count bigint, binary_area double precision, percent_area double precision, total_area double precision) AS
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
        SELECT rv.area_reference_id as area_id, rv.second_area_reference_id as cat_id
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
        gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom, t.prj_value
        FROM transformation t, sample_geog_levels sgl
        inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
        inner join boundaries bound on bound.geog_instance_id = gi.id
        WHERE sgl.id = sample_geog_lvl_id
        ), r_table as
        (
        SELECT p.geog_instance_id, p.geog_instance_label, ST_Union(ST_Reclass(ST_Clip(r.rast, bnd_num, ST_Transform(p.geom, p.prj_value), TRUE),1,l.exp, '8BUI',0)) as rast
        FROM lookup l, cat_rast c, polygon p inner join rasters r on ST_Intersects(r.rast, ST_Transform(p.geom, p.prj_value))
        WHERE r.raster_variable_id = (c.cat_id)
        GROUP by p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
        ), a_table as
        (
        SELECT p.geog_instance_id, p.geog_instance_label, ST_union(ST_Clip(r.rast, ST_Transform(p.geom, p.prj_value))) as rast
        FROM lookup l, cat_rast c, polygon p inner join rasters r on ST_Intersects(r.rast, ST_Transform(p.geom, p.prj_value))
        WHERE r.raster_variable_id = (c.area_id)
        GROUP by p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
        ), calc as
        (
        SELECT r.geog_instance_id, r.geog_instance_label, (ST_SummaryStats(r.rast)).*, (ST_SummaryStats(a.rast)).sum as total_area,
        (ST_SummaryStats(ST_MapAlgebra(r.rast, 1, a.rast, 1, '[rast1]*[rast2]', '32BUI'))).sum as binary_area
        FROM r_table r inner join a_table a on (r.geog_instance_id = a.geog_instance_id)
        )
        SELECT c.geog_instance_id, c.geog_instance_label, c.count as pixel_count, c.binary_area,
        c.binary_area / c.total_area as percent_area, c.total_area as total_area
        FROM calc c;

        END;

        $BODY$
    LANGUAGE 'plpgsql';
    SQL
    
    execute(sql)
    
    
  end
end


