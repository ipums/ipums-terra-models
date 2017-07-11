# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateRasterVariableGroupMemberships < ActiveRecord::Migration

  
  def change
    create_table :raster_variable_group_memberships, :id => false do |t|
      t.column  :raster_variable_id,       :bigint, :null => false
      t.column  :raster_group_id,          :bigint, :null => false
    end
    foreign_key(:raster_variable_group_memberships, :raster_variable_id)
    foreign_key(:raster_variable_group_memberships, :raster_group_id)
 
  end
end
