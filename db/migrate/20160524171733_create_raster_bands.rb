# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterBands < ActiveRecord::Migration


  def up
    create_table :raster_bands do |t|
      t.integer :band_num
      t.timestamps
    end
  end


  def down
    drop_table :raster_bands
  end

end
