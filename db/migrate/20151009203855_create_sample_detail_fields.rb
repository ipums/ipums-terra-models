# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateSampleDetailFields < ActiveRecord::Migration

  def change
    create_table :sample_detail_fields do |t|
      t.integer :sample_detail_group_id
      t.string :name
      t.string :label
      t.integer :order
      t.boolean :summary_only
      t.text :help_text
      t.timestamps
    end
  end
end
