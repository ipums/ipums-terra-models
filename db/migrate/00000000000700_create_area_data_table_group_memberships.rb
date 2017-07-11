# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateAreaDataTableGroupMemberships < ActiveRecord::Migration

  
  def change
    create_table :area_data_table_group_memberships, :id => false do |t|
      t.column  :area_data_table_id,          :bigint
      t.column  :area_data_table_group_id,     :bigint
    end
    foreign_key(:area_data_table_group_memberships, :area_data_table_id)
    foreign_key(:area_data_table_group_memberships, :area_data_table_group_id)
 
  end
end
