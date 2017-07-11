# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateTerrapopModelsExtractRequestFormats < ActiveRecord::Migration

  def change
    create_table :extract_request_formats do |t|
      t.column   :code, :string, limit: 64
      t.column   :description, :text
      t.timestamps
    end
    
    change_column :extract_request_formats, :id, :bigint
    add_column :extract_requests, :extract_request_format_id, :bigint
  end
end
