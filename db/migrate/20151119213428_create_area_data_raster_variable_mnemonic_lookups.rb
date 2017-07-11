# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateAreaDataRasterVariableMnemonicLookups < ActiveRecord::Migration

  def change
    
    create_table :area_data_raster_variable_mnemonic_lookups do |t|
      t.column   :composite_mnemonic, :string, length: 255, default: "not null"
      t.column   :mnemonic, :string, length: 32, default: "not null"
      t.column   :raster_operation_opcode, :string, length: 255
      t.column   :geog_level, :string, length: 32, default: "not null"
      t.column   :dataset_label, :string, length: 64, default: "not null"
      t.column   :description, :text
      t.timestamps
    end
    
    add_index :area_data_raster_variable_mnemonic_lookups, :composite_mnemonic, {name: :index_area_data_raster_variable_composite_mnemonic}
    add_index :area_data_raster_variable_mnemonic_lookups, :mnemonic, {name: :area_data_raster_variable_lookups_mnemonic }
    
  end
end
