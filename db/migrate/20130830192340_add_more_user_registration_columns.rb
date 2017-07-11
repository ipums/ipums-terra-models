# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddMoreUserRegistrationColumns < ActiveRecord::Migration

  def up
    add_column :users, :address_line_1,             :string, :limit => 128
    add_column :users, :address_line_2,             :string, :limit => 128
    add_column :users, :address_line_3,             :string, :limit => 128
    add_column :users, :city,                       :string, :limit => 128
    add_column :users, :state,                      :string, :limit => 64
    add_column :users, :postal_code,                :string, :limit => 32
    add_column :users, :registration_country,       :string, :limit => 128
    add_column :users, :country_of_origin,          :string, :limit => 256
    add_column :users, :personal_phone,             :string, :limit => 64
    add_column :users, :institutional_affiliation,  :string, :limit => 128
    add_column :users, :explain_no_affiliation,     :text
    add_column :users, :institution,                :string, :limit => 128
    add_column :users, :inst_email,                 :string, :limit => 128
    add_column :users, :inst_web,                   :string, :limit => 128
    add_column :users, :inst_boss,                  :string, :limit => 128
    add_column :users, :inst_address_line_1,        :string, :limit => 128
    add_column :users, :inst_address_line_2,        :string, :limit => 128
    add_column :users, :inst_address_line_3,        :string, :limit => 128
    add_column :users, :inst_city,                  :string, :limit => 128
    add_column :users, :inst_state,                 :string, :limit => 64
    add_column :users, :inst_postal_code,           :string, :limit => 32
    add_column :users, :inst_registration_country,  :string, :limit => 128
    add_column :users, :inst_phone,                 :string, :limit => 64
    add_column :users, :has_ethics,                 :boolean
    add_column :users, :ethical_board,              :string, :limit => 128
    add_column :users, :field,                      :string, :limit => 128
    add_column :users, :academic_status,            :string, :limit => 128
    add_column :users, :research_type,              :string, :limit => 64
    add_column :users, :research_description,       :text
    add_column :users, :health_research,            :boolean
    add_column :users, :funder,                     :text
    add_column :users, :opt_in,                     :boolean
    add_column :users, :no_fees,                    :boolean
    add_column :users, :cite,                       :boolean
    add_column :users, :send_copy,                  :boolean
    add_column :users, :data_only,                  :boolean
    add_column :users, :good_not_evil,              :boolean
    add_column :users, :no_redistribution,          :boolean
    add_column :users, :learning_only,              :boolean
    add_column :users, :non_commercial,             :boolean
    add_column :users, :confidentiality,            :boolean
    add_column :users, :secure_data,                :boolean
    add_column :users, :scholarly_publication,      :boolean
    add_column :users, :discipline,                 :boolean
  end

  def down
  end
end
