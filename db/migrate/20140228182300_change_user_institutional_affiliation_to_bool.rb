# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class ChangeUserInstitutionalAffiliationToBool < ActiveRecord::Migration

  class User < ActiveRecord::Base
  end

  def up
    # add a temp column for the data transfer
    add_column :users, :institutional_affiliation_temp, :boolean

    # transfer the data
    User.reset_column_information
    User.all.each do |user|
      if user.institutional_affiliation == 'yes'
        user.institutional_affiliation_temp = true
      elsif user.institutional_affiliation == 'no'
        user.institutional_affiliation_temp = false
      end
      user.save
    end

    # drop the original column
    remove_column :users, :institutional_affiliation

    # rename the temp column to the original one
    rename_column :users, :institutional_affiliation_temp, :institutional_affiliation

  end

  def down
    # add a temp column for the data transfer
    add_column :users, :institutional_affiliation_temp, :string, :limit => 128

    # transfer the data
    User.reset_column_information
    User.all.each do |user|
      if user.institutional_affiliation == true
        user.institutional_affiliation_temp = 'yes'
      elsif user.institutional_affiliation == false
        user.institutional_affiliation_temp = 'no'
      end
      user.save
    end

    # drop the original column
    remove_column :users, :institutional_affiliation

    # rename the temp column to the original one
    rename_column :users, :institutional_affiliation_temp, :institutional_affiliation

  end
end
