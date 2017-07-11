# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddGeographicLeveltoGeogInstance < ActiveRecord::Migration

  def up
    add_column :geog_instances, :geog_code, :string, :limit => 10
    add_column :geog_instances, :str_code, :string, :limit => 16
    add_index :geog_instances, :geog_code
    add_index :geog_instances, :str_code
  end

  def down
  end
end
