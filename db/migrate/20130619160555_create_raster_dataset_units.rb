# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterDatasetUnits < ActiveRecord::Migration

  def change
    create_table :raster_dataset_units do |t|
      t.column    :label,     :string, :limit => 128
      t.column    :mnemonic,  :string, :limit => 32
      t.timestamps
    end
  end
end
