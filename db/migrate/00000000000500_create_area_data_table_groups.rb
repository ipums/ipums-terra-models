# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateAreaDataTableGroups < ActiveRecord::Migration

  def change
    create_table :area_data_table_groups do |t|
      t.column    :name,            :string
      t.column    :display_order,   :integer
      t.column    :hidden,          :boolean
      t.timestamps
    end
    
    add_index :area_data_table_groups, :name
    
  end
end
