# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AreaDataTableGroupMembership < ActiveRecord::Base

  belongs_to :area_data_table_group, :inverse_of => :area_data_table_group_memberships

  # the inverse relationship on area_data_table is a has_and_belongs_to_many. If and when that gets changed to a :has_many :through
  # then this should get an :inverse_of as well.
  belongs_to :area_data_table
end
