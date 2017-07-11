# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class SampleDetailValue < ActiveRecord::Base

  belongs_to :sample_detail_field
  belongs_to :sample

  validates :sample_detail_field, presence: true
  validates :sample, presence: true

  def to_s
    self.value
  end
end
