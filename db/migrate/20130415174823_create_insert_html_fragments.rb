# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateInsertHtmlFragments < ActiveRecord::Migration

  def change
    
    create_table :insert_html_fragments do |t|
      t.column  :name,     :string, :limit => 255
      t.column  :content,  :text
      t.timestamps
    end
    
    add_index :insert_html_fragments, :name
    
  end
end
