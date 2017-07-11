# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateApiLogs < ActiveRecord::Migration

  def change
    
    create_table :api_logs do |t|
      t.column      :api_key, :text
      t.column      :action,  :text
      t.column      :extra,   :text
      t.timestamps
    end
    
    add_index :api_logs, :api_key
    
  end
end
