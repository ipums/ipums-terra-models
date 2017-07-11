# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CategoricalToBinaryAsRaster < ActiveRecord::Migration

  def change
    sql =<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_categorical_raster_to_binary_tiff(IN smpl_geog_lvl_id integer, IN rast_var_id integer, IN band_num integer DEFAULT 1)
      RETURNS TABLE (tiff bytea) AS
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
            ),transformation as
            (
              SELECT ST_SRID(r.rast) as prj_value
                          FROM rasters r
                          WHERE r.raster_variable_id = (select rv.second_area_reference_id from raster_variables rv where rv.id = rast_var_id limit 1) LIMIT 1
            ),polygon as
            (
            SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
            gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom
            FROM transformation t, sample_geog_levels sgl
            inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
            inner join boundaries bound on bound.geog_instance_id = gi.id
            WHERE sgl.id = smpl_geog_lvl_id
            ), binary_rast AS
            (
            SELECT p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code, ST_union(ST_Clip(r.rast, band_num,p.geom, TRUE)) as rast
            FROM polygon p inner join rasters r on ST_Intersects(r.rast, p.geom)
            WHERE r.raster_variable_id = (select rv.second_area_reference_id from raster_variables rv where rv.id = rast_var_id limit 1)
            GROUP by p.sample_geog_level_id, p.geog_instance_id, p.geog_instance_label, p.geog_instance_code
            )
            select ST_AsTiff(ST_Union(r.rast),'LZW', max(t.prj_value)) as tiff from binary_rast r, transformation t;

        END;
    $BODY$
    LANGUAGE 'plpgsql';
    SQL
 
    execute(sql)
  end
end



