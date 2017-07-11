# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateMaps < ActiveRecord::Migration

  def change
    
    create_table :maps do |t|
      t.column      :source_id,         :bigint
      t.column      :country_id,        :bigint
      t.column      :country_level_id,  :bigint
      t.column      :year_represented,  :date
      t.column      :id_code_digits,    :bigint
      t.column      :labeled,           :boolean
      t.column      :name,              :string, :limit => 128
      t.column      :source_file,       :string
      t.column      :num_units,         :bigint
      t.column      :description,       :text
      t.timestamps
    end
    
    foreign_key(:maps, :country_id)
    foreign_key(:maps, :country_level_id)

  end
end
