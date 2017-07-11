# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class ChangeRasterFunctionOwners < ActiveRecord::Migration

  def change
    username = Rails.configuration.database_configuration[Rails.env.to_s]['username']
    statements = [
'ALTER FUNCTION _raster_constraint_pixel_types(raster) SET search_path=pg_catalog,public,postgis;',
"ALTER FUNCTION _raster_constraint_out_db(raster) SET search_path=pg_catalog,public,postgis;",
"ALTER FUNCTION st_coveredby(geometry,geometry) SET search_path=pg_catalog,public,postgis;",
"ALTER FUNCTION _raster_constraint_nodata_values (raster) SET Search_path=\'#{username}\', pg_catalog,public;",
"ALTER FUNCTION _raster_constraint_out_db (raster) SET Search_path=\'#{username}\',pg_catalog,public;",
"ALTER FUNCTION _raster_constraint_pixel_types(raster) SET Search_path=\'#{username}\',pg_catalog,public;",
"ALTER FUNCTION _overview_constraint(raster, integer, name, name, name) SET Search_path=\'#{username}\', pg_catalog,public;"
]
    statements.each do |statement|
      execute(statement)
    end
  end
end
