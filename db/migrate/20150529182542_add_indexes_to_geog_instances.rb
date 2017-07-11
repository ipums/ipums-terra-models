# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddIndexesToGeogInstances < ActiveRecord::Migration

  def change
    add_index :geog_instances, :parent_id
    add_index :geog_instances, :terrapop_sample_id
    add_index :geog_instances, :code
    add_index :geog_instances, :sample_geog_level_id
    
  end
end
