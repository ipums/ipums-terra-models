# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'mnemonic_utility'


class RasterGroup < ActiveRecord::Base
  include MnemonicUtility
  belongs_to :parent, class_name: "RasterGroup", foreign_key: "parent_id"

  has_many :children, class_name: "RasterGroup", foreign_key: "parent_id"
  has_many :raster_variable_group_memberships
  has_many :raster_variables, through: :raster_variable_group_memberships

  has_and_belongs_to_many :tags, join_table: :raster_groups_tags

  def parent_mnemonic
    parent.mnemonic
  end

  def sorted_children
    sort_operation == 'name' ? children.order(:name) : children
  end


  def self.sort_collection(rg_id, collection)
    raster_group = RasterGroup.where(id: rg_id).first
    return collection if raster_group.nil? || !raster_group.respond_to?('sort_operation')
    case raster_group.sort_operation
    when 'mnemonic'
      collection.order(:mnemonic)
    when 'label'
      collection.order(:label)
    when 'mnemonic_month'
      sort_by_mnemonic_month(collection)
    else
      collection
    end
  end


  def sorted_variables
    case sort_operation
    when 'mnemonic'
      raster_variables.order(:mnemonic)
    when 'label'
      raster_variables.order(:label)
    when 'mnemonic_month'
      sort_by_mnemonic_month(raster_variables)
    when 'alphabetical_weight'
      raster_variables.sort_by{ |e| [e.sort_weight, e.label] }
    else
      raster_variables
    end
  end

  def table_type
    self.class.to_s
  end

  def child_count
    raster_variables.count
  end

  def in_cart_count(mnemonics)
    raster_variables.where(mnemonic: mnemonics).count
  end

  def raster_datasets_count
    nil
  end

  def _raster_dataset_id_
    nil
  end

  def description
    name
  end

  def begin_year
    nil
  end

  def end_year
    nil
  end

  def raster_data_type_id
    nil
  end

end
