# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateVariableGroups < ActiveRecord::Migration

  def change
    
    create_table :variable_groups do |t|
      t.column    :name,      :string
      t.column    :abbrev,    :string
      t.column    :rectype,   :string
      t.column    :parent_id, :bigint
      t.column    :order,     :bigint
      t.timestamps
    end
    
    foreign_key_raw(:variable_groups, :parent_id, :variable_groups, :id)
    
    add_index :variable_groups, :parent_id
        
  end
end
