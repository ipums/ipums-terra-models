# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class SwapColumnsForSampleDetailFields < ActiveRecord::Migration

  def change
    remove_column :sample_detail_fields, :summary_only
    add_column :sample_detail_fields, :summary_only, :boolean, after: :updated_at
  end
end
