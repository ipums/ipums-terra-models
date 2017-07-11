# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateUiTextSnippet < ActiveRecord::Migration

  def change
    create_table :ui_text_snippet do |t|
      t.column  :key_text,      :text
      t.column  :text_snippet,  :text
      t.timestamps
    end

    add_index :ui_text_snippet, :key_text
  end
end
