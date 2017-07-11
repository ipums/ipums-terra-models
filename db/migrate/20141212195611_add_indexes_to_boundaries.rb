# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddIndexesToBoundaries < ActiveRecord::Migration

  def change
    
    execute("DROP INDEX IF EXISTS boundaries_geog_gist_idx")
    execute("DROP INDEX IF EXISTS boundaries_geom_gist_idx")
    execute("CREATE INDEX boundaries_geog_gist_idx ON boundaries USING gist(geog)")
    execute("CREATE INDEX boundaries_geom_gist_idx ON boundaries USING gist(geom)")
    
  end
end
