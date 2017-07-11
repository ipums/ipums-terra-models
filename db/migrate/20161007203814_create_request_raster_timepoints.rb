# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRequestRasterTimepoints < ActiveRecord::Migration

  def up
    create_table :request_raster_timepoints do |t|
      t.column :raster_timepoint_id,  :bigint, :null => false
      t.column :extract_request_id, :bigint, :null => false
      t.timestamps
    end
    foreign_key(:request_raster_timepoints, :raster_timepoint_id)
    foreign_key(:request_raster_timepoints, :extract_request_id)
   end

  def down
    drop_table :request_raster_timepoints
  end
end
