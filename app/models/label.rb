# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class Label < ActiveRecord::Base


  self.table_name = "tags"

  has_and_belongs_to_many :extract_requests, :join_table => "extract_requests_labels"

end