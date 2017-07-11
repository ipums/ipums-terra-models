# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateAreaDataVariables < ActiveRecord::Migration

  def change
    
    create_table :area_data_variables do |t|
      t.column      :area_data_table_id,    :bigint
      t.column      :measurement_type_id,   :bigint
      t.column      :mnemonic,              :string, :limit => 32
      t.column      :long_mnemonic,         :string, :limit => 64
      t.column      :label,                 :string
      t.column      :description,           :text
      t.column      :hidden,                :boolean
      t.timestamps
    end
    
    foreign_key(:area_data_variables, :area_data_table_id)
    foreign_key(:area_data_variables, :measurement_type_id)

  end
end
