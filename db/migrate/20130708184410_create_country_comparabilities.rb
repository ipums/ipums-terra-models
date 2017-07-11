# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateCountryComparabilities < ActiveRecord::Migration

  def change
    create_table :country_comparabilities do |t|
      t.column          :variable_id,  :bigint
      t.column          :country_id,   :bigint
      t.column          :comparability, :text
      t.timestamps
    end
    
    foreign_key :country_comparabilities, :variable_id
    foreign_key :country_comparabilities, :country_id
    
  end
end
