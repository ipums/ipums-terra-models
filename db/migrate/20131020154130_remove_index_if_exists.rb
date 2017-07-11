# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RemoveIndexIfExists < ActiveRecord::Migration

  def up
    execute "DROP INDEX IF EXISTS index_ui_text_snippet_on_key_text"
    execute "DROP TABLE IF EXISTS text_snippet"
  end

  def down
  end
end
