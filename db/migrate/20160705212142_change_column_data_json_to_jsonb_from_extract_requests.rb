# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class ChangeColumnDataJsonToJsonbFromExtractRequests < ActiveRecord::Migration

  def change
    change_column_default :extract_requests, :data, nil
    change_column :extract_requests, :data, 'jsonb USING CAST(data as jsonb)'
    add_index :extract_requests, :data, using: :gin
  end
end
