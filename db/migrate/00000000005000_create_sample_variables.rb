# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateSampleVariables < ActiveRecord::Migration

  def change
    create_table :sample_variables do |t|
      t.column      :variable_id,   :bigint
      t.column      :sample_id,     :bigint
      t.column      :universe_id,   :bigint
      t.column      :anchor_form,   :string
      t.column      :anchor_inst,   :string
      t.timestamps
    end
    
    add_index :sample_variables, :variable_id
    add_index :sample_variables, :universe_id
    add_index :sample_variables, :sample_id
    
    foreign_key(:sample_variables, :variable_id)
    foreign_key(:sample_variables, :sample_id)
    foreign_key(:sample_variables, :universe_id)

  end
end
