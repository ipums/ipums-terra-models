# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateVariableSources < ActiveRecord::Migration

  def change
    create_table :variable_sources do |t|
      t.column :makes,      :bigint, :null => false
      t.column :is_made_of, :bigint, :null => false
      t.timestamps
    end
    
    foreign_key_raw(:variable_sources, :is_made_of, :sample_variables, :id)
    foreign_key_raw(:variable_sources, :makes,      :sample_variables, :id)

    add_index :variable_sources, :makes
    add_index :variable_sources, :is_made_of
    
  end
end
