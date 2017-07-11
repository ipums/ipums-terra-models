# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class VariableSource < ActiveRecord::Base

  
  belongs_to :sample_variable, :foreign_key => :is_made_of, :inverse_of => :variable_sources

  belongs_to :is_made_of, :class_name => "SampleVariable", :foreign_key => :is_made_of
  belongs_to :makes,      :class_name => "SampleVariable", :foreign_key => :makes

end
