# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddKeyColumnTorasterVariableGroupMemberships2 < ActiveRecord::Migration

  def change
    remove_column :raster_variable_group_memberships, :id
    add_column :raster_variable_group_memberships, :id, :primary_key
    add_index :raster_variable_group_memberships, :id
    
  end
end
