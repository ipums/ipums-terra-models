# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateCommonVariables < ActiveRecord::Migration

  def change
    
    create_table :common_variables do |t|
      t.column    :variable_name, :string,  :limit => 25
      t.column    :record_type,   :string,  :limit => 10
      t.timestamps
    end
    
    add_index :common_variables, :variable_name
    
  end
end
