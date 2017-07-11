# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class StstandardizeTerrapopReclassifyCategoricalRasterToBinarySummarizV3 < ActiveRecord::Migration

  def change
    
  sql =<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_reclassify_categorical_raster_to_binary_summariz_v4(IN sample_geog_lvl_id bigint, IN rasters_id bigint, IN bnd_num integer)
        RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, pixel_count bigint, binary_area double precision, percent_area double precision, total_area double precision) AS
        $BODY$

    DECLARE
        area_raster_id integer;
        categorical_raster_id integer;

    BEGIN
        SELECT rv.area_reference_id as area_id into area_raster_id FROM raster_variables rv WHERE rv.id =  rasters_id ;
        SELECT rv.second_area_reference_id into categorical_raster_id FROM raster_variables rv WHERE rv.id = rasters_id ;

        RETURN QUERY

        WITH lookup AS
            (
            SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
            FROM raster_variables WHERE id IN (
                    select raster_variable_classifications.mosaic_raster_variable_id 
                    from raster_variable_classifications
                    where raster_variable_classifications.raster_variable_id = rasters_id)
            ), transformation as
            (
            SELECT ST_SRID(r.rast) as prj_value
            FROM rasters r
            WHERE r.raster_variable_id = categorical_raster_id
            LIMIT 1
            ), polygon as
            (
            SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
            gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom
            FROM transformation t, sample_geog_levels sgl
            inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
            inner join boundaries bound on bound.geog_instance_id = gi.id
            WHERE sgl.id = sample_geog_lvl_id
            ), r_table as
            (
            SELECT p.geog_instance_id, p.geog_instance_label, ST_union(ST_Reclass(ST_Clip(r.rast, bnd_num ,p.geom, TRUE),1,l.exp, '8BUI',0)) as rast
            FROM lookup l, polygon p inner join rasters r on ST_Intersects(r.rast, p.geom)
            WHERE r.raster_variable_id = categorical_raster_id
            GROUP by p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
            ), a_table as
            (
            SELECT p.geog_instance_id, p.geog_instance_label, ST_union(ST_Clip(r.rast, p.geom)) as rast
            FROM lookup l, polygon p inner join rasters r on ST_Intersects(r.rast, p.geom)
            WHERE r.raster_variable_id = area_raster_id
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
    LANGUAGE plpgsql VOLATILE;
    SQL
    
    execute sql
  end
end
