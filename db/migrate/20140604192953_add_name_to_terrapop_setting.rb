# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

class AddNameToTerrapopSetting < ActiveRecord::Migration


  class TerrapopSetting < ActiveRecord::Base
  end


  def up
    add_column :terrapop_settings, :name, :string

    TerrapopSetting.reset_column_information
    settings = {}
    TerrapopSetting.order('id desc').each do |tp|
      tp.data.each do |k,v|
        settings[k] = v
      end
    end

    TerrapopSetting.destroy_all
    settings.each do |k,v|
      tp_setting = TerrapopSetting.new
      tp_setting.name = k
      tp_setting.data = {'value' => v}
      tp_setting.save!
    end

    change_column :terrapop_settings, :name, :string, null: false
    add_index :terrapop_settings, :name, unique: true
    remove_index :terrapop_settings, name: 'terrapop_settings_gin_data'
  end


  def down
    TerrapopSetting.reset_column_information
    settings = {}
    TerrapopSetting.all.each { |tp| settings[tp.id] = {tp.name => tp.data['value']} }
    settings.each do |id,data|
      tp = TerrapopSetting.find(id)
      tp.data = data
      tp.save!
    end

    remove_index :terrapop_settings, column: :name
    remove_column :terrapop_settings, :name
    execute "CREATE INDEX terrapop_settings_gin_data ON terrapop_settings USING GIN(data)"
  end

end
