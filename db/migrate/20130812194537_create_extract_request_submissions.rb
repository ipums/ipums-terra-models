# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateExtractRequestSubmissions < ActiveRecord::Migration

  def change
    create_table :extract_request_submissions do |t|
      t.column      :extract_request_id,    :bigint
      t.column      :submitted_at,  :timestamp
      t.timestamps
    end
    
    foreign_key :extract_request_submissions, :extract_request_id
    
  end
end
