# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddColumnGeom3ToTerrascopeGeographicBoundaries < ActiveRecord::Migration


  def up
    sql=<<SQL
    ALTER TABLE terrascope.geographic_boundaries ADD COLUMN geom_3 geometry;
SQL
    ActiveRecord::Base.connection.execute(sql)

    sql=<<SQL
    CREATE VIEW terrascope.sgl_boundaries_view AS SELECT * FROM terrascope.geographic_boundaries;
SQL
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
    sql=<<SQL
    ALTER TABLE terrascope.geographic_boundaries DROP COLUMN geom_3 RESTRICT;
SQL
    ActiveRecord::Base.connection.execute(sql)

    sql=<<SQL
    DROP VIEW terrascope.sgl_boundaries_view;
SQL
    ActiveRecord::Base.connection.execute(sql)
  end

end
