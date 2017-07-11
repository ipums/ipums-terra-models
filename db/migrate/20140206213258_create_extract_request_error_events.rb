# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateExtractRequestErrorEvents < ActiveRecord::Migration

  def change
    
    create_table :extract_request_error_events do |t|
      t.column    :extract_request_id, :bigint
      t.column    :error_event_id, :bigint
      t.timestamps
    end
    
    foreign_key :extract_request_error_events, :extract_request_id
    foreign_key :extract_request_error_events, :error_event_id
    
  end
end
