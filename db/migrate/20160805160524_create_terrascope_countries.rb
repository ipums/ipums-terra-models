# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateTerrascopeCountries < ActiveRecord::Migration

  def up
    sql=<<SQL
CREATE TABLE terrascope.countries (
  id integer,
  label text,
  iso_code text,
  country_level_id bigint,
  sample_years numeric[],
  num_years bigint,
  current_year numeric,
  samples integer[],
  geog_levels varchar(100)[],
  geom geometry,
  geom_1 geometry,
  geom_2 geometry,
  geom_3 geometry
);
SQL
    execute(sql)

    create_view=<<SQL
    CREATE VIEW terrascope.countries_view AS SELECT * FROM terrascope.countries;
SQL
    execute(create_view)

  end

  def down
    drop_countries=<<SQL
    DROP TABLE terrascope.countries CASCADE;
SQL
    execute(drop_countries)
  end
end
