# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateFrequencies < ActiveRecord::Migration

  def change
    create_table :frequencies do |t|
      t.column      :category_id,   :bigint
      t.column      :sample_id,     :bigint
      t.column      :frequency,     :integer
      t.column      :variable_id,   :bigint
      t.column      :code,          :string, :limit => 50
      t.timestamps
    end
    
    # foreign_key(:frequencies, :category_id) # Feb 9, 2013; ccd states this column is not used in a foreign-key-way; removing constraint
    foreign_key(:frequencies, :sample_id)
    foreign_key(:frequencies, :variable_id)
  end
end
