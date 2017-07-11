# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class SampleDetailField < ActiveRecord::Base

  belongs_to :sample_detail_group

  validates :sample_detail_group, presence: true
  validates :name, presence: true
  validates :label, presence: true
end
