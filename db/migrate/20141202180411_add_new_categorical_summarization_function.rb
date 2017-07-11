# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddNewCategoricalSummarizationFunction < ActiveRecord::Migration

  def change

    sql = <<-SQL

    CREATE OR REPLACE FUNCTION terrapop_categorical_raster_v0(IN sample_geog_lvl_id bigint, IN rasters_id bigint)
      RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, num_class bigint, mod_class double precision, total_area double precision) AS
    $BODY$
        DECLARE

        BEGIN

        RETURN QUERY
        WITH poly_table AS (
          SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
          gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, (SELECT ST_SRID(r.rast) FROM rasters r WHERE r.raster_variable_id = rasters_id LIMIT 1)) as geom
          FROM sample_geog_levels sgl
          inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
          inner join boundaries bound on bound.geog_instance_id = gi.id
          WHERE sgl.id = sample_geog_lvl_id
        ),
         cat_rast AS
        (
        select p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code, ST_Union(ST_Clip(r.rast, p.geom)) as rast
          from poly_table p inner join rasters r on ST_Intersects(r.rast, p.geom)
          where r.raster_variable_id = rasters_id
          group by p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
        ),
        area_rast AS
        (
        select p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code, (ST_SummaryStats(ST_Union(ST_Clip(r.rast, p.geom)))).sum as categorical_area
          from poly_table p inner join rasters r on ST_Intersects(r.rast, p.geom)
          where r.raster_variable_id = ( select rv.area_reference_id from raster_variables rv where rv.id = rasters_id limit 1 )
          group by p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
        )
        SELECT area_rast.geog_instance_id, area_rast.geog_instance_label, cat_num_classes.number_of_classes, cat_mode_class.value as modal_class, area_rast.categorical_area 
        FROM area_rast inner join 
            (
            SELECT cat_count.geog_instance_id, cat_count.geog_instance_label, count(cat_count.value) as number_of_classes
            FROM (
                select cat_rast.geog_instance_id, cat_rast.geog_instance_label, (ST_valuecount(cat_rast.rast)).value
                from cat_rast
            ) cat_count
            GROUP BY cat_count.geog_instance_id, cat_count.geog_instance_label
            ) cat_num_classes on (area_rast.geog_instance_id = cat_num_classes.geog_instance_id) inner join 
            (
            SELECT DISTINCT ON (cat_rast.geog_instance_id, cat_rast.geog_instance_label)
            cat_rast.geog_instance_id, cat_rast.geog_instance_label, (ST_valuecount(cat_rast.rast)).*
            FROM cat_rast
            ORDER BY cat_rast.geog_instance_id, cat_rast.geog_instance_label, (ST_valuecount(cat_rast.rast)).count DESC
            ) cat_mode_class ON (area_rast.geog_instance_id = cat_mode_class.geog_instance_id);

        END;

        $BODY$
      LANGUAGE plpgsql VOLATILE;
    SQL

    execute sql

  end
end
