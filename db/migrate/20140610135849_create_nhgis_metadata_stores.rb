# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateNhgisMetadataStores < ActiveRecord::Migration

  def change
    create_table :nhgis_metadata_stores do |t|
      t.column      :ds_code,              :string, limit: 128
      t.column      :dt_label,             :string, limit: 256
      t.column      :adv_label,            :string, limit: 64
      t.column      :adv_id,               :bigint
      t.column      :ts_id,                :bigint
      t.column      :ts_label,             :string, limit: 128
      t.column      :tst_id,               :bigint
      t.column      :tst_label,            :string, limit: 128
      t.column      :gl_id,                :bigint
      t.column      :gl_istads_id,         :string, limit: 128 
      t.column      :dg_id,                :bigint
      t.column      :dg_relative_pathname, :text
      t.column      :df_id,                :bigint
      t.column      :df_filename,          :string, limit: 64
      t.timestamps
    end
    
    add_index :nhgis_metadata_stores, :adv_id
    add_index :nhgis_metadata_stores, :ts_id
    add_index :nhgis_metadata_stores, :tst_id
    add_index :nhgis_metadata_stores, :gl_id
    add_index :nhgis_metadata_stores, :gl_istads_id
    add_index :nhgis_metadata_stores, :dg_id
    add_index :nhgis_metadata_stores, :df_id
    
  end
end
