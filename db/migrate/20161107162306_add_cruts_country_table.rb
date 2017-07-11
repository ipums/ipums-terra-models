# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddCrutsCountryTable < ActiveRecord::Migration

  def change
    
    sql = "CREATE SCHEMA IF NOT EXISTS climate"
    
    execute(sql)
    
    #create table climate.cruts_countries(id bigint, country_id bigint, country text, iso_code text, cruts_all_template text, cruts_pre_template text );
    
    sql = "create table climate.cruts_countries(id bigserial, country_id bigint, country text, iso_code text, cruts_all_template text, cruts_pre_template text )"
    
    execute(sql)
    
    sql = "CREATE UNIQUE INDEX climate_cruts_countries_country_id_index ON climate.cruts_countries(country_id)"
    
    execute(sql)
    
  end
end
