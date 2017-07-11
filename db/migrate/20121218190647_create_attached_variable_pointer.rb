# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateAttachedVariablePointer < ActiveRecord::Migration

  def up
    
   # Basically a list of valid pointers. The mnemonic matches mnemonics of microdata variables in the 'variables' table.
   # We don't need a foreign key or anything; these are mostly for selection and testing purposes.
    create_table "attached_variable_pointers", :force => true do |t|
      t.string "mnemonic"
      t.string "suffix"
      t.string "label"
      t.timestamps
    end
    
  end

  def down
    #drop_table :attached_variable_pointers
  end
end
