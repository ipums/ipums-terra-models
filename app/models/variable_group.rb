# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class VariableGroup < ActiveRecord::Base


  has_many :variables
  has_many :children, class_name: "VariableGroup", foreign_key: "parent_id"

  belongs_to :parent, class_name: "VariableGroup", foreign_key: "parent_id"


  def rectype_long
    rectype == 'H' ? 'HOUSEHOLD' : 'PERSON'
  end


end
