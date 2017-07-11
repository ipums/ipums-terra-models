# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateCategories < ActiveRecord::Migration

  def change
    create_table :categories do |t|
      t.column      :variable_id,     :bigint
      t.column      :metadata_id,     :integer
      t.column      :code,            :string
      t.column      :label,           :string, :limit => 1024
      t.column      :general_label,   :string
      t.column      :syntax_label,    :string
      t.column      :indent,          :integer
      t.column      :general_indent,  :integer
      t.column      :informational,   :boolean
      t.timestamps
    end
   
    foreign_key(:categories, :variable_id)
    add_index :categories, :variable_id
    
  end
end
