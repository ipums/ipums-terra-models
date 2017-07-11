# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateAreaDataTables < ActiveRecord::Migration

  def change
    create_table :area_data_tables do |t|
      t.column      :label,               :string
      t.column      :code,                :string, :limit => 10
      t.column      :documentation,       :text
      t.column      :universe,            :text
      t.column      :aggregation_method,  :string
      t.column      :additivity,          :string
      t.column      :hidden,              :boolean
      t.timestamps
    end
  end
end
