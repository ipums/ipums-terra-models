# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RenameColumnsCruts322Countries < ActiveRecord::Migration

  def up
    sql1=<<SQL
alter table climate.cruts_322_countries rename cruts_global_template to cruts_322_global_template;
SQL
    execute(sql1)

    sql2=<<SQL
alter table climate.cruts_322_countries rename cruts_landonly_template to cruts_322_landonly_template;
SQL
    execute(sql2)
  end

  def down
    sql1=<<SQL
alter table climate.cruts_322_countries rename cruts_322_global_template to cruts_global_template;
SQL
    execute(sql1)
    sql2=<<SQL
alter table climate.cruts_322_countries rename cruts_322_landonly_template to cruts_landonly_template;
SQL
    execute(sql2)
  end

end
