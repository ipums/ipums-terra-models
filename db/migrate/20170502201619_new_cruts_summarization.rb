# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class NewCrutsSummarization < ActiveRecord::Migration

  def change
    
    sql=<<SQL
    CREATE OR REPLACE FUNCTION terrapop_cruts_timepoint_analysis_new(sample_geog_level_id bigint, raster_var_id bigint, timepoint date) 
    RETURNS TABLE(geog_instance_id bigint, geog_place text, min double precision, max double precision, mean double precision, count bigint ) AS

    $BODY$

    DECLARE 
      query_string text := '';
      cruts_mnemonic text := '';
      template text := '';
  
    BEGIN

      SELECT netcdf_mnemonic INTO cruts_mnemonic FROM raster_variables WHERE id = raster_var_id;
      SELECT netcdf_template INTO template FROM raster_variables WHERE id = raster_var_id;
  
      query_string := $$

      WITH boundaries as
      (
    	  SELECT gi.id as geoid, gi.label as description, bound.geom as geom
    	  FROM sample_geog_levels sgl
    	   join geog_instances gi on sgl.id = gi.sample_geog_level_id
    	   join boundaries bound on bound.geog_instance_id = gi.id
    	  WHERE sgl.id  = $$ || sample_geog_level_id || $$
      ),

      clipped_grids as
      (
    	select b.geoid, b.description, p.pixel_id, st_intersection(b.geom, p.grid_geom) as geom
    	from boundaries b join climate.cruts_322_global_template p on st_intersects(b.geom, p.grid_geom)
      ),

      clipped_grid_weights as
      (
      	select g.geoid, g.description, g.pixel_id, st_area(st_transform(g.geom, 3410)) as area_weight, g.geom
      	from clipped_grids g
      ),

      climate_data as
      (
      	select w.geoid, w.description, w.pixel_id, c.$$|| cruts_mnemonic ||$$, w.area_weight
      	from climate.cruts_322 c JOIN clipped_grid_weights w ON w.pixel_id = c.pixel_id
      	where "time" = '$$ || timepoint || $$'
	
      )

      select geoid::bigint, description::text, min(c.$$|| cruts_mnemonic ||$$) as min, max(c.$$|| cruts_mnemonic ||$$) as max, sum(c.$$|| cruts_mnemonic ||$$ * c.area_weight)/sum(c.area_weight) as mean, count(geoid)::bigint AS count
      from climate_data c
      group by geoid, description
      order by geoid;
  
      $$;
  
      RAISE NOTICE  ' % ', query_string;
  
      RETURN QUERY execute query_string;
  
  
      END;

      $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;    
SQL

    execute(sql)
    
  end
end
