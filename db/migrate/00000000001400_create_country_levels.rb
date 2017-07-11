# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateCountryLevels < ActiveRecord::Migration

  def change
    create_table :country_levels do |t|
      t.column      :geog_unit_id,    :bigint
      t.column      :country_id,      :bigint
      t.column      :label,           :string
      t.column      :code,            :string
      t.column      :level_order,     :string
      t.timestamps
    end
    
    foreign_key(:country_levels, :geog_unit_id)
    foreign_key(:country_levels, :country_id)

    add_index :country_levels,        :code, :unique => true
  end
end
