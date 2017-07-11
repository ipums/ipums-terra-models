# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateUsers < ActiveRecord::Migration

  def change
    
    create_table :users do |t|
      
      t.string      :firstname,            :limit => 128, :default => "", :null => false
      t.string      :lastname,             :limit => 128, :default => "", :null => false
      t.string      :email,                               :default => "", :null => false
      t.string      :encrypted_password,   :limit => 256, :default => "", :null => false
      t.datetime    :confirmed_at
      t.datetime    :confirmation_sent_at
      t.string      :confirmation_token
      t.string      :unconfirmed_email
      t.string      :reset_password_token
      t.datetime    :reset_password_sent_at
      t.string      :remember_token
      t.datetime    :remember_created_at
      t.integer     :sign_in_count,                       :default => 0
      t.datetime    :current_sign_in_at
      t.datetime    :last_sign_in_at
      t.string      :current_sign_in_ip
      t.string      :last_sign_in_ip
      t.integer     :failed_attempts,                     :default => 0
      t.string      :unlock_token
      t.string      :authentication_token
      t.column      :user_role_id,  :bigint
      t.datetime    :locked_at
      t.timestamps
      
    end
    
    foreign_key(:users, :user_role_id)

    add_index :users, :email,                :unique => true
    add_index :users, :unconfirmed_email
    add_index :users, :reset_password_token, :unique => true
    add_index :users, :confirmation_token,   :unique => true
    add_index :users, :unlock_token,         :unique => true
    add_index :users, :authentication_token, :unique => true
    
  end
  
end