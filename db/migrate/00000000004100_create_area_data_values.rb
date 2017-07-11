# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateAreaDataValues < ActiveRecord::Migration

  def change
    create_table :area_data_values do |t|
      t.column    :sample_level_area_data_variable_id,  :bigint
      t.column    :area_data_variable_id,               :bigint
      t.column    :geog_instance_id,                    :bigint
      t.column    :value,                               :decimal, :precision => 64, :scale => 10
      t.column    :error,                               :decimal, :precision => 64, :scale => 10
      t.column    :precision,                           :integer
      t.timestamps
    end
    
    foreign_key(:area_data_values, :sample_level_area_data_variable_id)
    foreign_key(:area_data_values, :area_data_variable_id)
    foreign_key(:area_data_values, :geog_instance_id)

  end
end
