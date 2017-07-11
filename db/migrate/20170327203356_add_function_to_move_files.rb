# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddFunctionToMoveFiles < ActiveRecord::Migration

  def change
    sql =<<SQL
    CREATE OR REPLACE FUNCTION terrapop_move_file_to( from_filepath text, to_filepath text) 
    RETURNS boolean AS

        $BODY$ 

        import os   

        if os.path.exists(from_filepath):
            os.rename(from_filepath, to_filepath)
            return True
        else:
            plpy.ERROR("Error moving %s to %s" %(from_filepath, to_filepath))
            return False

        $BODY$

    LANGUAGE plpythonu VOLATILE;    
SQL
    
    execute(sql)
  end
end
