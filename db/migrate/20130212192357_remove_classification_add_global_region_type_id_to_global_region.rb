# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RemoveClassificationAddGlobalRegionTypeIdToGlobalRegion < ActiveRecord::Migration

  def up
    remove_column :global_regions, :classification
    
    add_column :global_regions, :global_region_type_id, :bigint
    
    foreign_key :global_regions, :global_region_type_id
    
  end

  def down
  end
end
