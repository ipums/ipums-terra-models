# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddForeignIndexToVariableAvailabilityCache < ActiveRecord::Migration

  def change
    
    add_index :variable_availability_caches, :variable_id
    foreign_key :variable_availability_caches, :variable_id
    
  end
end
