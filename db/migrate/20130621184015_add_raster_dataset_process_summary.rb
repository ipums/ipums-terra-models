# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddRasterDatasetProcessSummary < ActiveRecord::Migration

  def up
    add_column :raster_datasets, :process_summary, :text
  end

  def down
  end
end
