# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateGeogInstances < ActiveRecord::Migration

  def change
    
    create_table :geog_instances do |t|
      t.column      :sample_geog_level_id,  :bigint
      t.column      :parent_id,             :bigint
      t.column      :label,                 :string
      t.column      :code,                  :decimal, :precision => 20, :scale => 0
      t.column      :shape_area,            :decimal
      t.column      :notes,                 :text
      t.column      :boundary_id,           :bigint
      t.timestamps
    end
    
    foreign_key_raw(:geog_instances, :parent_id, :geog_instances, :id)
    foreign_key(:geog_instances, :sample_geog_level_id)
    foreign_key(:geog_instances, :boundary_id)

  end
end
