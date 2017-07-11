# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateCacheItems < ActiveRecord::Migration

  
  def up
    connection = ActiveSupport::Cache::ActiveRecordStore::CacheItem.connection
    connection.create_table :cache_items do |t|
      t.string :key
      t.text :value
      t.text :meta_info
      t.datetime :expires_at
      t.datetime :created_at
      t.datetime :updated_at
    end

    connection.add_index :cache_items, :key, :unique => true
    connection.add_index :cache_items, :expires_at
    connection.add_index :cache_items, :updated_at
  end

  def down
    ActiveSupport::Cache::ActiveRecordStore::CacheItem.connection.drop_table :cache_items
  end
  
end
