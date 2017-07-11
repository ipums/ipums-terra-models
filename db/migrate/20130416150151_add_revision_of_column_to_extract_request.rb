# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddRevisionOfColumnToExtractRequest < ActiveRecord::Migration

  def change
    
    add_column :extract_requests, :revision_of, :bigint
    foreign_key_raw(:extract_requests, :revision_of, :extract_requests, :id)
    
  end
end