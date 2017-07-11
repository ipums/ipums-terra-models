# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class RequestSample < ActiveRecord::Base

  belongs_to :sample
  belongs_to :extract_request

  after_initialize  :init_callback
  
  def custom_person_frequency
    self.sample.p_records / self.custom_sampling_ratio
  end

  def custom_household_frequency
    self.sample.h_records / self.custom_sampling_ratio
  end

  def custom_percent_density
    self.sample.density / self.custom_sampling_ratio
  end

  #compute random first hh to sample
  def generate_first_household_sampled

    # max_household is equal to ceiling(custom_sampling_ratio)
    max_household = custom_sampling_ratio.ceil

    # first_household-sampled should be at least 1 but no greater than the max_household
    self.first_household_sampled = rand(max_household) + 1;
  end

  private
  def init_callback
    self.custom_sampling_ratio = 1.0
    generate_first_household_sampled
  end
  
end
