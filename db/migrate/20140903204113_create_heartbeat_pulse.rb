# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateHeartbeatPulse < ActiveRecord::Migration

  def change
    create_table :heartbeat_pulses do |t|
      t.column :heartbeat_id, :bigint
      t.timestamps
    end
    foreign_key :heartbeat_pulses, :heartbeat_id
    add_index :heartbeat_pulses, :heartbeat_id
  end
end
