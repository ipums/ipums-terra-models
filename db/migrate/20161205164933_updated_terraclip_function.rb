# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class UpdatedTerraclipFunction < ActiveRecord::Migration

  def change
    sql =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_raster_to_image_v2(
        IN sample_geog_level_id bigint,
        IN rasters_id bigint,
        IN raster_bnd integer DEFAULT 1)
      RETURNS TABLE(img bytea) AS
    $BODY$

          DECLARE
                data_raster text := '';
                raster_type text := '';
                rasters_schema text := '';
                query text := '';
                nodatavalue integer;

          BEGIN

          -- Every raster_variable_id goes through this query.. 
          -- Step 1: Get Information about the raster, raster_variable_type, raster_table, and nodataValue
          -- Step 2: Verify Boundary Geometry
          -- Step 3
          -- Determine if the raster_variable is categorical or Binary,
          -- If Binary and go through the reclassification steps the output raster data type is '8BUI'  8-bit unsigned integer
          -- If Categorical the output raster data type is '8BUI'  8-bit unsigned integer
          -- If you are not Binary or Categorical you are ELSE, 

          --STEP 1
          SELECT lower(rmdv.mnemonic_type) as mnemonic_type
          into raster_type
          FROM rasters_metadata_view rmdv
          WHERE  rmdv.id = rasters_id;

          SELECT schema || '.' || tablename as tablename
          FROM rasters_metadata_view rmw
          INTO data_raster
          WHERE rmw.id = rasters_id;

          query := $$ 
          SELECT ST_BandNoDataValue(rast)::integer
          FROM $$ || data_raster || $$ 
          LIMIT 1 $$ ;

          Execute query INTO nodatavalue;

          --STEP 2
          query := $$ CREATE TEMP TABLE terrapop_clip_boundary AS
          WITH raster_projection AS
          (
          select st_srid(rast) as prj
          from $$ || data_raster || $$ 
          limit 1
          )
          SELECT sgl.id as sample_geog_level_id, gi.id as geog_instance_id, gi.label as geog_instance_label, gi.code as geog_instance_code, ST_Transform(bound.geom, prj.prj) as geom,
          ST_IsValidReason(ST_Transform(bound.geom, prj.prj)) as reason
          FROM raster_projection prj,
          sample_geog_levels sgl
          inner join geog_instances gi on sgl.id = gi.sample_geog_level_id
          inner join boundaries bound on bound.geog_instance_id = gi.id
          WHERE sgl.id = $$ || sample_geog_level_id || $$ $$;

          RAISE NOTICE  ' % ', query;

          EXECUTE query;

          Update terrapop_clip_boundary
          SET geom = ST_MakeValid(geom)
          WHERE reason <> 'Valid Geometry';

          DELETE FROM terrapop_clip_boundary
          WHERE ST_IsValidReason(geom) <> 'Valid Geometry';

          IF raster_type = 'binary' THEN

            WITH second_area_reference as
            (
            SELECT second_area_reference_id
            FROM rasters_metadata_view rmdv
            WHERE rmdv.id = rasters_id
            )
            SELECT DISTINCT schema || '.' || tablename as table_name
            into data_raster
            FROM rasters_metadata_view rmdv
            inner join second_area_reference on rmdv.id = second_area_reference.second_area_reference_id;

            query := $$ WITH lookup AS
            (
            SELECT replace(replace(array_agg(classification::text || ':1')::text, '{', ''), '}', '') as exp
            FROM raster_variables WHERE id IN (
                select raster_variable_classifications.mosaic_raster_variable_id
                from raster_variable_classifications
                where raster_variable_classifications.raster_variable_id = $$ || rasters_id || $$ )
            ),projection as
            (
            SELECT ST_SRID(r.rast) as srid
            FROM $$ || data_raster || $$ r
            LIMIT 1
            ), polygon as
            (
            SELECT sample_geog_level_id, geog_instance_id, geog_instance_label, geog_instance_code, geom
            FROM terrapop_clip_boundary
            )
            SELECT ST_AsTIFF(ST_Reclass(ST_Clip(r.rast, $$ || raster_bnd || $$ ,p.geom, $$ || nodatavalue || $$, TRUE), 1, l.exp, '8BUI', $$ || nodatavalue || $$), ARRAY[1], 'LZW', prj.srid ) as  img
            FROM lookup l, projection prj, polygon p inner join $$ || data_raster || $$ r on ST_Intersects(r.rast,p.geom) $$;

          ELSE

            SELECT schema
            FROM rasters_metadata_view rmdv
            INTO rasters_schema
            WHERE rmdv.id = rasters_id;

            SELECT schema || '.' || tablename as tablename
            FROM rasters_metadata_view rmdv
            INTO data_raster
            WHERE rmdv.id = rasters_id;

            IF rasters_schema = 'modis' or rasters_schema = 'landcover' THEN

              query := $$ WITH projection as
              (
              SELECT ST_SRID(rast) as srid
              FROM $$ || data_raster || $$
              Limit 1
              ),polygon as
              (
              SELECT sample_geog_level_id, geog_instance_id, geog_instance_label, geog_instance_code, geom
              FROM terrapop_clip_boundary
              ),raster_clip as
              (
              SELECT ST_Clip(r.rast, $$ || raster_bnd || $$, p.geom, $$ || nodatavalue || $$, False) AS rast
              FROM polygon p inner join $$ || data_raster || $$  r on ST_Intersects(r.rast,p.geom)
              )
              SELECT ST_AsTIFF(rast, 'LZW', prj.srid) as  img
              FROM raster_clip, projection prj $$ ;

            ELSE
              query := $$ WITH projection as
              (
              SELECT ST_SRID(rast) as srid
              FROM $$ || data_raster || $$
              Limit 1
              ),rastervariable_band as
              (
              SELECT rmdv.band_num
              FROM rasters_metadata_view rmdv
              WHERE rmdv.id = $$ || rasters_id || $$
              ),polygon as
              (
              SELECT sample_geog_level_id, geog_instance_id, geog_instance_label, geog_instance_code, geom
              FROM terrapop_clip_boundary
              ),raster_clip as
              (
              SELECT ST_Clip(r.rast, rvb.band_num, p.geom, $$ || nodatavalue || $$, False) AS rast
              FROM rastervariable_band rvb, polygon p inner join $$ || data_raster || $$  r on ST_Intersects(r.rast,p.geom)
              )
              SELECT ST_AsTIFF(rast, 'LZW', prj.srid) as  img
              FROM raster_clip, projection prj $$ ;

            END IF;
          END IF;

          RAISE NOTICE  ' % ', query;
          RETURN QUERY execute query;

          END;
        $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100
      ROWS 1000;    
SQL

    execute(sql)

  end
end
