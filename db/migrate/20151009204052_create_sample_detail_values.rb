# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateSampleDetailValues < ActiveRecord::Migration

  def change
    create_table :sample_detail_values do |t|
      t.integer :sample_id
      t.integer :sample_detail_field_id
      t.text :value
      t.timestamps

      t.index [:sample_id, :sample_detail_field_id], unique: true, name: 'idx_sample_field'
    end
  end
end
