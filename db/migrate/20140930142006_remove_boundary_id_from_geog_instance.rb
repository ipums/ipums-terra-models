# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RemoveBoundaryIdFromGeogInstance < ActiveRecord::Migration

  def change
    remove_constraint_if_exists :geog_instances, :geog_instances_boundary_id_fkey
    remove_column :geog_instances, :boundary_id
  end
end
