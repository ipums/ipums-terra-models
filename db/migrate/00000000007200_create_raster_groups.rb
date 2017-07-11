# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterGroups < ActiveRecord::Migration

  def change
    
    create_table :raster_groups do |t|
      t.column      :name,          :string
      t.column      :mnemonic,      :string, :limit => 64
      t.column      :display_order, :integer
      t.column      :parent_id,     :bigint
      t.column      :hidden,        :boolean
      t.timestamps
    end
    
    foreign_key_raw(:raster_groups, :parent_id, :raster_groups, :id)
    
    add_index :raster_groups, :parent_id
    add_index :raster_groups, :name
    add_index :raster_groups, :display_order
    
  end
end
