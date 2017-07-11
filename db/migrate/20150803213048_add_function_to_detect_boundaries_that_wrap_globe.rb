# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddFunctionToDetectBoundariesThatWrapGlobe < ActiveRecord::Migration

  def change
    
    sql=<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_boundary_wrap(sample_geog_lvl_id bigint) RETURNS Boolean AS
    $BODY$
      DECLARE

        far_west double precision;
        far_east double precision;

      BEGIN

        with boundbox as
        (
        select ST_X((ST_Dumppoints(ST_convexhull(geom))).geom) as coordinates
          from sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id inner join boundaries bound on bound.geog_instance_id = gi.id WHERE sgl.id = sample_geog_lvl_id
        )
        select min(coordinates)
        into far_west
        from boundbox;
    

        with boundbox as
        (
        select ST_X((ST_Dumppoints(ST_convexhull(geom))).geom) as coordinates
          from sample_geog_levels sgl inner join geog_instances gi on sgl.id = gi.sample_geog_level_id inner join boundaries bound on bound.geog_instance_id = gi.id WHERE sgl.id = sample_geog_lvl_id
        )
        select max(coordinates)
        into far_east
        from boundbox;

        RAISE NOTICE  ' % ', far_west;
        RAISE NOTICE  ' % ', far_east;

        IF far_west < -178 AND far_east > 178 THEN
          RETURN True;
        ELSE
          RETURN False;
        END IF;

      END;
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    SQL
    
    execute sql
  end
end
