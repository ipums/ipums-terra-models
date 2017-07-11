# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateBoundaries < ActiveRecord::Migration

  def change
    create_table :boundaries do |t|
      t.column      :map_id,            :bigint
      t.column      :geog_instance_id,  :bigint
      t.column      :description,       :string, :length => 256
      t.column      :geog,              :geography
      t.timestamps
    end

    foreign_key(:boundaries, :map_id)

  end
end
