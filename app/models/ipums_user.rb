# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

require 'ipumsi_user_database'


class IpumsUser < IpumsiUserActiveRecord::Base
  self.table_name = :users

  validates :first_name, :last_name, :salt, :crypted_password, presence: true
  validates :email, uniqueness: true, format: {with: /\A[^@]+@[^@]+\.[^@]+\z/}


  def get_ipumsi_registration
    IpumsRegistration.find_by(id: self.id)
  end


end
