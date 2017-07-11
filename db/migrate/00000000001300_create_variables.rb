# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class CreateVariables < ActiveRecord::Migration

  def change
    create_table :variables do |t|
      t.column      :mnemonic,                  :string, :limit => 32
      t.column      :long_mnemonic,             :string, :limit => 64
      t.column      :label,                     :string
      t.column      :variable_group_id,         :bigint
      t.column      :record_type,               :string, :limit => 1
      t.column      :is_svar,                   :boolean
      t.column      :sample_id,                 :bigint
      t.column      :is_general_detailed,       :boolean
      t.column      :is_old,                    :boolean
      t.column      :is_dq_flag,                :boolean
      t.column      :description,               :text
      t.column      :general_comparability,     :text
      t.column      :ipums_comparability,       :text
      t.column      :questionnaires,            :boolean
      t.column      :manual_codes_display,      :text
      t.column      :nontabulated,              :boolean
      t.column      :hide_extract_status,       :integer
      t.column      :case_select_type,          :string
      t.column      :default_order,             :integer
      t.column      :column_start,              :integer
      t.column      :column_width,              :integer
      t.column      :general_column_width,      :integer
      t.column      :show_questionnaires_link,  :boolean
      t.column      :hide_status,               :integer
      t.column      :data_type,                 :string
      t.column      :preselect_status,          :integer
      t.column      :implied_decimal_places,    :integer
      t.column      :replicate_weight,          :boolean
      t.column      :original_record_type_id,   :integer
      t.column      :nhis_mnemonic,             :string
      t.column      :do_not_attach,             :boolean
      t.column      :is_sda,                    :boolean
      t.column      :is_preliminary,            :boolean
      t.column      :constructed,               :boolean
    t.column :original_name, :string
      t.timestamps
    end

    foreign_key(:variables, :sample_id)
    foreign_key(:variables, :variable_group_id)
  
    add_index :variables, :variable_group_id
    add_index :variables, :sample_id
    add_index :variables, :mnemonic
    add_index :variables, :is_svar
    

  end
end
