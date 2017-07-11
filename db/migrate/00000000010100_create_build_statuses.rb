# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateBuildStatuses < ActiveRecord::Migration

  def change
    create_table :build_statuses do |t|
      t.column      :val,         :integer
      t.column      :label,       :string, :limit => 32
      t.column      :description, :string, :limit => 128
      t.timestamps
    end
  end
end
