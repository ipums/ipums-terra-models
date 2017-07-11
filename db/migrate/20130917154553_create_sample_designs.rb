# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateSampleDesigns < ActiveRecord::Migration

  def change
    create_table :sample_designs do |t|
      t.string  :filename,    :limit => 1024
      t.text    :document,    :null  => false
      t.column  :country_id,  :bigint, :null => false
      t.timestamps
    end
    
    add_index :sample_designs, :country_id
    foreign_key :sample_designs, :country_id
    
  end
end
