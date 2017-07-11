# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateTerrapopSettings < ActiveRecord::Migration


  def change

    create_table :terrapop_settings do |t|
      t.hstore :data
      t.timestamps
    end

    ###
    #
    # Using a GIN index instead of a GIST index
    #
    # GIN indexes take longer to create but are generally faster to query
    #
    # more information:
    # http://www.postgresql.org/docs/9.2/static/textsearch-indexes.html
    #

    execute "CREATE INDEX terrapop_settings_gin_data ON terrapop_settings USING GIN(data)"

  end

end
