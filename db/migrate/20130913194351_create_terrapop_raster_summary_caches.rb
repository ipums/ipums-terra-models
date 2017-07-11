# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateTerrapopRasterSummaryCaches < ActiveRecord::Migration

  def change
    create_table :terrapop_raster_summary_caches do |t|
      t.column :sample_geog_level_id, :bigint
      t.column :raster_variable_id, :bigint
      t.column :raster_operation_name, :text
      t.column :geog_instance_id, :bigint
      t.column :geog_instance_label, :text
      t.column :geog_instance_code, :decimal, :precision => 20, :scale => 0
      t.column :raster_mnemonic, :text
      t.column :boundary_area, :decimal, :precision => 64, :scale => 10
      t.column :summary_value, :decimal, :precision => 20, :scale => 4
      t.timestamps
    end
    
    foreign_key :terrapop_raster_summary_caches, :sample_geog_level_id
    foreign_key :terrapop_raster_summary_caches, :raster_variable_id
    foreign_key :terrapop_raster_summary_caches, :geog_instance_id
    
    add_index :terrapop_raster_summary_caches, :sample_geog_level_id
    add_index :terrapop_raster_summary_caches, :raster_variable_id
    add_index :terrapop_raster_summary_caches, :raster_operation_name
    
    add_index :terrapop_raster_summary_caches, [:sample_geog_level_id, :raster_variable_id, :raster_operation_name], :name => 'terrapop_raster_summary_caches_triplet_idx'
    
  end
end
