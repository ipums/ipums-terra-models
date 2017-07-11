# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class ChangeTypeOfColumnDataFromExtractRequests < ActiveRecord::Migration

  def change
    remove_index :extract_requests, name: 'extract_requests_gin_data'
    change_column :extract_requests, :data, 'json USING CAST(data as json)', null: false, default: '{}'
  end
end
