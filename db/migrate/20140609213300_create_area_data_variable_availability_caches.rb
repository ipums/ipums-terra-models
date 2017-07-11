# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateAreaDataVariableAvailabilityCaches < ActiveRecord::Migration

  def change
    create_table :area_data_variable_availability_caches do |t|
      t.column     :area_data_variable_id,  :bigint,   null: false
      t.column     :json,  :text
      t.timestamps
    end
    
    add_index :area_data_variable_availability_caches, :area_data_variable_id, name: :adv_cache_adv_idx
    foreign_key :area_data_variable_availability_caches, :area_data_variable_id
    
  end
end
