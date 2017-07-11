# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddReadFileInPythonPostgres < ActiveRecord::Migration

  def change
    sql =<<SQL
    CREATE OR REPLACE FUNCTION readfile_as_base64(filepath text)
      RETURNS text
    AS $$
      import os
      import base64
      try:
        #return open(filepath).read()
      
        with open(filepath, "rb") as image_file:
          encoded_string = base64.b64encode(image_file.read())
        
        return encoded_string
      
      except (IOError, OSError):
        raise NameError("File Not Found")
    $$ LANGUAGE plpythonu;
SQL

    execute(sql)

  end
end
