# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class EvenNewerGlcBinaryFunction < ActiveRecord::Migration

  def change
    sql =<<-SQL
      CREATE OR REPLACE FUNCTION terrapop_glc_binary_summarization_v4(IN sample_geog_lvl_id bigint, IN rasters_id bigint)
          RETURNS TABLE(geog_instance_id bigint, geog_instance_label character varying, binary_area double precision, total_area double precision, percent_area double precision) AS
            $BODY$
            BEGIN
            RETURN QUERY
        WITH srid as

        (

        	SELECT st_srid(r.rast) as srid FROM rasters r

        	where r.raster_variable_id = rasters_id

        	limit 1

        ),

       bounds as
        (

        	SELECT sgl.id as sample_geog_level_id, gi.id as gid, gi.label as label, gi.code as geog_instance_code, st_transform(bound.geog::geometry, srid.srid) as geom

        	FROM srid, sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id inner join boundaries bound on bound.geog_instance_id = gi.id

        	where sgl.id = sample_geog_lvl_id group by sgl.id, gi.id, gi.label, gi.code, bound.geog

        ),
		
    		bin_rast as 
    		(
    			SELECT b.gid as gid, b.label as label, ST_Union(ST_Clip(r.rast, b.geom)) as rast
    			FROM bounds b inner join rasters r on ST_Intersects(r.rast, b.geom)
    			where r.raster_variable_id = rasters_id group by b.gid, b.label
    		),

    		area_reference_id as (select rv.area_reference_id as id from raster_variables rv where rv.id = rasters_id limit 1),

    		area_ref_rast as
    		(
    			SELECT b.gid as gid, b.label as label, ST_Union(ST_Clip(r.rast, b.geom)) as rast
    			FROM area_reference_id a, bounds b inner join rasters r on ST_Intersects(r.rast, b.geom)
    			where r.raster_variable_id = a.id group by b.gid, b.label
    		),

    		binary_area as
    		(
    			select b.gid, b.label, (ST_SummaryStats(ST_MapAlgebra(b.rast, 1, a.rast, 1, '[rast1]*[rast2]'))).sum as binary_area
    			FROM bin_rast b inner join area_ref_rast a on b.gid = a.gid
    			group by b.gid, b.label, a.rast, b.rast
    		),

    		total_area as
    		(
    			SELECT a.gid as gid, a.label as label, (ST_SummaryStats(a.rast, true)).sum as total_area
    			FROM area_ref_rast a group by a.gid, a.label, a.rast order by a.label
    		),

    		percent_area as
    		(
    			select a.gid as gid, a.label as label, a.binary_area/b.total_area as percent_area
    			from binary_area a, total_area b where a.gid = b.gid order by a.label
    		)

    		SELECT b.gid, b.label, b.binary_area, t.total_area, p.percent_area
    		FROM binary_area b inner join total_area t on b.gid = t.gid inner join percent_area p on t.gid = p.gid;

            END;
            $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100
      ROWS 1000;
    SQL
    
    execute(sql)
  end
end
