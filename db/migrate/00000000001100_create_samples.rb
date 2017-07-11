# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateSamples < ActiveRecord::Migration

  def change
    create_table :samples do |t|
      t.column      :name,                :string
      t.column      :country_id,          :bigint
      t.column      :year,                :integer
      t.column      :density,             :decimal, :precision => 6, :scale => 3
      t.column      :note,                :string
      t.column      :h_records,           :integer
      t.column      :p_records,           :integer
      t.column      :is_old,              :boolean
      t.column      :use_suffix,          :boolean
      t.column      :data_file_name,      :string
      t.column      :hide_status,         :integer
      t.column      :sample_value,        :string
      t.column      :list,                :string
      t.column      :short_description,   :string
      t.column      :display_group,       :string
      t.column      :is_puerto_rico,      :boolean
      t.column      :freq_order,          :integer
      t.column      :medium_description,  :string
      t.column      :data_provider,       :string, :limit => 512
      t.column      :long_description,    :string
      t.column      :display_order,       :integer
      t.column      :is_sda,              :boolean
      t.column      :month,               :integer
      t.column      :fingerprint_sha512,  :string, :limit => 128, :default => nil
      t.timestamps
    end
    
  end
end
