# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddJoinFieldsToSampleGeogLevel < ActiveRecord::Migration

  def change
    add_column :sample_geog_levels, :gisjoin1_start, :bigint, null: true
    add_column :sample_geog_levels, :gisjoin1_width, :bigint, null: true
    add_column :sample_geog_levels, :gisjoin2_start, :bigint, null: true
    add_column :sample_geog_levels, :gisjoin2_width, :bigint, null: true
  end
end
