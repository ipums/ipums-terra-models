# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateErrorEvents < ActiveRecord::Migration

  def change
    create_table :error_events do |t|
      t.column    :user_id,         :bigint,  :default => nil
      t.column    :message,         :text,    :null => false
      t.column    :supplementary,   :text
      t.timestamps
    end
  end
end
