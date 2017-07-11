# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateExtractRequestsLabelsJoinTable < ActiveRecord::Migration

  def up

    create_table :extract_requests_labels, :id => false do |t|
      t.column      :extract_request_id, :bigint
      t.column      :label_id,           :bigint
      t.column      :user_id,            :bigint
      t.column      :visible,            :boolean, :default => true, :null => false
    end

    foreign_key(:extract_requests_labels, :extract_request_id)
    foreign_key_raw(:extract_requests_labels, :label_id, :tags, :id)
    foreign_key(:extract_requests_labels, :user_id)

  end

  def down
    drop table :extract_requests_labels
  end
end
