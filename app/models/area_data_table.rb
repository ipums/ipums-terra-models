# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AreaDataTable < ActiveRecord::Base


  has_many :area_data_variables
  has_and_belongs_to_many :area_data_table_groups, join_table: :area_data_table_group_memberships

  alias_attribute :name, :label
  alias_attribute :mnemonic, :code


  def availability_by_country_and_long_year
    self.area_data_variables.map{ |area_data_variable| area_data_variable.availability_by_country_and_long_year }.flatten.uniq.sort
  end


  def datasets
    self.area_data_variables.first.datasets
  end


  def category_id
    category = area_data_table_groups.first
    category.nil? ? nil : category.id
  end

end
