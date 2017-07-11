# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class Category < ActiveRecord::Base


  has_many :frequencies
  belongs_to :variable


  def general_code
    informational? ? '' : (variable.general_column_width.nil? ? code : code[0, variable.general_column_width])
  end


  def formatted_label
    syntax_label || label
  end


end
