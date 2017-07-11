# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class NewImprovedSridDetectionFunction < ActiveRecord::Migration

  def change
    sql =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_raster_variable_projection(raster_variable_id bigint, raster_bnd bigint) 
    RETURNS bigint AS

    $BODY$

        DECLARE
        query text := '';
        data_raster text := '';
        srid bigint;

        BEGIN

        WITH all_raster_variable_ids AS
        (
        select id 
        from raster_variables
        )

        SELECT rmw.schema || '.' || rmw.tablename as tablename
        FROM all_raster_variable_ids a INNER JOIN rasters_metadata_view rmw ON rmw.id = a.id
        INTO data_raster
        WHERE rmw.id = raster_variable_id AND rmw.band_num = raster_bnd;

        query := $$ 
        Select ST_SRID(rast)
        FROM $$ || data_raster || $$ 
        limit 1    $$ ;

        RAISE NOTICE  ' % ', query;
        Execute query INTO srid;
        RETURN srid;
        END;

    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100;
SQL

    execute(sql)

  end
end
