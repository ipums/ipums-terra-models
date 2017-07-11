# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class NewRastersTable < ActiveRecord::Migration

  def change
    create_table :rasters_new do |t|
      t.column    :raster_variable_id, :bigint
      t.column    :table_name, :text
      t.column    :area_reference_id,  :bigint
      t.column    :second_area_reference_id, :bigint
      t.column    :r_table_schema, :text
      t.timestamps
    end

    add_index :rasters_new, :raster_variable_id
    add_index :rasters_new, :area_reference_id
    add_index :rasters_new, :second_area_reference_id

    foreign_key :rasters_new, :raster_variable_id
  end
end
