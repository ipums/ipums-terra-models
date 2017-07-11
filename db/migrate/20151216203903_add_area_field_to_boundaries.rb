# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddAreaFieldToBoundaries < ActiveRecord::Migration

  def change
    add_column :boundaries, :area, :decimal, precision: 64, scale: 10
  end
end
