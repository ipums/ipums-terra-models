# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'nhgis_database'

module Nhgis
  class DataFileType < NhgisActiveRecord::Base

    def var_code
      label[0]
    end

    def is_estimate?
      var_code == 'E'
    end

    def is_margin_of_error?
      var_code == 'M'
    end
  end
end