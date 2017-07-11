# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class UpdateRasterTimepoints < ActiveRecord::Migration

  def up
    remove_column :raster_timepoints, :label
    remove_column :raster_timepoints, :mnemonic

    add_column :raster_timepoints, :interval, :string
    add_column :raster_timepoints, :band, :integer
    add_column :raster_timepoints, :timepoint, :string
  end

  def down
    remove_column :raster_timepoints, :interval
    remove_column :raster_timepoints, :band
    remove_column :raster_timepoints, :timepoint

    add_column :raster_timepoints, :label, :string
    add_column :raster_timepoints, :mnemonic, :string
  end
end

