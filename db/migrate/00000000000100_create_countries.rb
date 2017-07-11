# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateCountries < ActiveRecord::Migration

  def change
    create_table :countries do |t|
      t.column      :short_name,    :string
      t.column      :full_name,     :string
      t.column      :continent,     :string
      t.column      :is_old,        :boolean
      t.column      :abbrev_long,   :text
      t.column      :hide_status,   :boolean
      t.column      :stats_office,  :string
      t.timestamps
    end
    
  end
end
