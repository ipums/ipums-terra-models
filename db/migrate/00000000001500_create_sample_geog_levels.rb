# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateSampleGeogLevels < ActiveRecord::Migration

  def change
    create_table :sample_geog_levels do |t|
      t.column      :country_level_id,    :bigint
      t.column      :terrapop_sample_id,  :bigint
      t.column      :label,               :string
      t.column      :code,                :string, :limit => 10
      t.column      :internal_code,       :string, :limit => 128
      t.column      :geolink_variable_id, :bigint
      t.timestamps
    end
    
    add_index :sample_geog_levels,      :code, :unique => true

    foreign_key(:sample_geog_levels, :country_level_id)
    foreign_key(:sample_geog_levels, :terrapop_sample_id)

    foreign_key_raw(:sample_geog_levels, :geolink_variable_id, :variables, :id)
  end
end
