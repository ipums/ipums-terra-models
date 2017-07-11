# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddIndexes < ActiveRecord::Migration

  def change
    execute("CREATE INDEX variables_mnemonic_sorted_asc ON variables (mnemonic ASC)")
    add_index :variables, [:is_svar, :is_old, :mnemonic]
    add_index :variables, [:is_svar, :is_old]
    add_index :variables, :is_old
  end
end
