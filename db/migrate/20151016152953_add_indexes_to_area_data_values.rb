# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddIndexesToAreaDataValues < ActiveRecord::Migration

  def change
    add_index :area_data_values, :sample_level_area_data_variable_id
    add_index :area_data_values, :geog_instance_id
    add_index :area_data_values, :area_data_variable_id
  end
end
