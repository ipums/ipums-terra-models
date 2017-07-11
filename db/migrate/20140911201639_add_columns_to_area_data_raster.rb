# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddColumnsToAreaDataRaster < ActiveRecord::Migration

  def change
    
    add_column :area_data_rasters, :label,         :string, limit: 128
    add_column :area_data_rasters, :mnemonic,      :string, limit: 32
    add_column :area_data_rasters, :value,         :decimal, :precision => 64, :scale => 10
    add_column :area_data_rasters, :cell_count,    :bigint
    add_column :area_data_rasters, :pop_per_pixel, :decimal, :precision => 64, :scale => 10
    
  end
end
