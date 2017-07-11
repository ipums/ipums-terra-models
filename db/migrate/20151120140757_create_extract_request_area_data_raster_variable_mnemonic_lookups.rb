# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateExtractRequestAreaDataRasterVariableMnemonicLookups < ActiveRecord::Migration

  def change
    create_table :extract_request_area_data_raster_variable_mnemonic_lookups do |t|
      t.column    :area_data_raster_variable_mnemonic_lookup_id, :bigint
      t.column    :extract_request_id, :bigint
      t.timestamps
    end
    
    add_index :extract_request_area_data_raster_variable_mnemonic_lookups, :area_data_raster_variable_mnemonic_lookup_id, {name: :er_adrv_mnemonic_lookup_index}
    add_index :extract_request_area_data_raster_variable_mnemonic_lookups, :extract_request_id, {name: :er_adrv}
    
    foreign_key :extract_request_area_data_raster_variable_mnemonic_lookups, :area_data_raster_variable_mnemonic_lookup_id
    foreign_key :extract_request_area_data_raster_variable_mnemonic_lookups, :extract_request_id
    
  end
end
