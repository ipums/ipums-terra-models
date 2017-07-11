# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class EvenMoreCorrectNewRastersTableInNewMakeJpeg2Function < ActiveRecord::Migration

  def change
    sql0 =<<-SQL
      DROP FUNCTION IF EXISTS terrapop_categorical_to_binary_as_raster_v1(integer, integer, integer);
    SQL
    
    
    sql=<<-SQL
     CREATE OR REPLACE FUNCTION terrapop_categorical_to_binary_as_raster_v1(IN sample_geog_lvl_id bigint, IN rast_id bigint, IN rast_band_num integer)
  RETURNS SETOF raster AS
$BODY$
DECLARE

    one_raster text := 'hello';
    query text := '';

    BEGIN

    WITH lookup AS
    (
    SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
    FROM raster_variables WHERE id IN (
            select raster_variable_classifications.mosaic_raster_variable_id
            from raster_variable_classifications
            where raster_variable_classifications.raster_variable_id =  rast_id )
    ), cat_rast as
    (
    SELECT rv.second_area_reference_id as cat_id
    FROM raster_variables rv
    WHERE rv.id =  rast_id
    )
    SELECT r_table_schema || '.' || table_name as tablename
    INTO one_raster
    FROM cat_rast inner join new_rasters on cat_rast.cat_id = new_rasters.raster_variable_id ;

    RAISE NOTICE  ' % ', one_raster;

    query := $$ WITH lookup AS
    (
    SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
      FROM raster_variables WHERE id IN (
            select raster_variable_classifications.mosaic_raster_variable_id
            from raster_variable_classifications
            where raster_variable_classifications.raster_variable_id = $$ || rast_id || $$)
    )
    , transformation as
    (
    SELECT ST_SRID(r.rast) as prj_value
    FROM $$ || one_raster || $$ r
    LIMIT 1
    ), polygon as
    (
    SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label,
    gi.code as geog_instance_code, ST_Transform(bound.geog::geometry, t.prj_value) as geom
    FROM transformation t, sample_geog_levels sgl
    inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
    inner join boundaries bound on bound.geog_instance_id = gi.id
    WHERE sgl.id = $$ || sample_geog_lvl_id || $$
    )
    SELECT ST_union(ST_Reclass(ST_Clip(r.rast, 1,p.geom, TRUE),1,l.exp, '8BUI',0)) as rast
    FROM lookup l, polygon p inner join $$ || one_raster || $$ r on ST_Intersects(r.rast,p.geom) $$ ;

    RAISE NOTICE  ' % ', query;

    RETURN QUERY execute query;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
    SQL
    
    execute sql0
    
    execute sql
  end
end
