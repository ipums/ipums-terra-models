# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateAreaDataVariableConstructions < ActiveRecord::Migration

  
  def change
    create_table :area_data_variable_constructions do |t|
      t.column    :variable_id,           :bigint,  :null => false
      t.column    :area_data_variable_id, :bigint,  :null => false
      t.timestamps
    end
    
    foreign_key :area_data_variable_constructions, :variable_id
    foreign_key :area_data_variable_constructions, :area_data_variable_id
    
    add_index :area_data_variable_constructions, :variable_id
    add_index :area_data_variable_constructions, :area_data_variable_id
    
  end
end
