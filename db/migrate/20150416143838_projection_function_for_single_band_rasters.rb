# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class ProjectionFunctionForSingleBandRasters < ActiveRecord::Migration

  def change
    sql1 =<<-SQL
    CREATE OR REPLACE FUNCTION terrapop_projection_number_from_single_band_raster(raster_id bigint)
    RETURNS integer AS
    $BODY$
      DECLARE prj_value integer;
      BEGIN
        WITH transformation as
        (
          SELECT ST_SRID(r.rast) AS prj_value
            FROM rasters r
            WHERE r.raster_variable_id = raster_id
            LIMIT 1
        )
        SELECT t.prj_value INTO prj_value FROM transformation t;
        
        RETURN prj_value;
      END;
    $BODY$
    LANGUAGE 'plpgsql';
    SQL
    
    execute(sql1)
    
  end
end
