# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterVariables < ActiveRecord::Migration

  def change
    create_table :raster_variables do |t|
      t.column    :mnemonic,              :string, :limit => 32, :null => false
      t.column    :long_mnemonic,         :string, :limit => 128
      t.column    :label,                 :string
      t.column    :raster_data_type_id,   :bigint
      t.column    :raster_dataset_id,     :bigint
      t.column    :filename,              :string
      t.column    :description,           :text
      t.column    :begin_year,            :int
      t.column    :end_year,              :int
      t.column    :units,                 :string
      t.column    :hidden,                :boolean
      t.column    :original_metadata,     :text
      t.column    :netcdf_mnemonic,       :text
      t.column    :netcdf_template,       :text
      t.timestamps
    end
    
    foreign_key(:raster_variables, :raster_data_type_id)

    add_index :raster_variables, :raster_dataset_id
    add_index :raster_variables, :raster_data_type_id
    add_index :raster_variables, :mnemonic
    add_index :raster_variables, :begin_year
    add_index :raster_variables, :end_year
    
  end
end
