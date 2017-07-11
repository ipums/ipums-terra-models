# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateSystemStatistics < ActiveRecord::Migration

  def change
    create_table :system_statistics do |t|
      t.column      :key,  :string, limit: 64, null: false, unique: true
      t.column      :value, :decimal, precision: 64, scale: 10
      t.timestamps
    end

    add_index :system_statistics, :key, unique: true

  end
end