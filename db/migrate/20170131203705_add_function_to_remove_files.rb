# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddFunctionToRemoveFiles < ActiveRecord::Migration

  def change
    sql =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_remove_file( file_path text )
      RETURNS boolean AS $BODY$ 

        import os   

        def remove_file(filePath):
          if os.path.exists(filePath):
              os.remove(filePath)
              return True
          else:
              plpy.warning("File: %s does not exist" % filePath)
              return False

        return remove_file(file_path)

      $BODY$ LANGUAGE plpythonu VOLATILE;
SQL
    
    execute(sql)
  end
end
