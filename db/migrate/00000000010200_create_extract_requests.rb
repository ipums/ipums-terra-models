# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateExtractRequests < ActiveRecord::Migration

  def change
    create_table :extract_requests do |t|
      t.column      :boundary_files,:boolean, :default => false
      t.column      :description,   :text
      t.column      :user_id,       :bigint
      t.column      :submitted,     :boolean, :default => false
      t.timestamps
    end

    foreign_key(:extract_requests, :user_id)

  end
end
