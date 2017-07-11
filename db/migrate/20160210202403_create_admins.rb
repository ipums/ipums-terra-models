# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateAdmins < ActiveRecord::Migration

  def change
    create_table :admins do |t|
      t.string :unique_id, limit: 36, null: false
      t.boolean :hide_nhgis_datasets, default: true
    end
    add_index :admins, :unique_id, unique: true
  end
end
