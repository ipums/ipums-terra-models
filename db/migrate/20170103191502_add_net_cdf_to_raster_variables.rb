# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddNetCdfToRasterVariables < ActiveRecord::Migration


 def up
   sql =<<SQL
     DROP TABLE climate.cruts_countries;
SQL
   ActiveRecord::Base.connection.execute(sql)
end

 def down
   sql=<<SQL
     CREATE TABLE climate.cruts_countries(id bigserial, country_id bigint, country text, iso_code text, cruts_all_template text, cruts_pre_template text );
SQL
   ActiveRecord::Base.connection.execute(sql)
 end


end
