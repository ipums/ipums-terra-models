# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

module TerrapopConfigurationModule

  ENVIRONMENTS = "environments"
  APPLICATION  = "application"
  COUNTRIES    = "countries"
  SETTINGS     = "settings"


  def self.before

    unless defined? @@configuration
      str = File.open(Rails.root.to_s + "/config/terrapop.yml", 'r') { |f| f.read }
      str = ERB.new(str).result
      @@configuration = YAML.load(str)
    end

    unless @@configuration.dig(APPLICATION, COUNTRIES).nil?
      if @@configuration[APPLICATION][COUNTRIES][0] == :all
        @@configuration[APPLICATION][COUNTRIES] = Country.order(:short_name).pluck(:short_name)
      end
    end

    if defined? ENV['SERVER_NAME']
      unless ENV['SERVER_NAME'].nil?
        #$stderr.puts "ServerName: #{ENV['SERVER_NAME']}"
        # this area will be arrived upon ONLY in the WebApp part of TP
        # we need to set/update a TerrapopSettings object with our current hostname
        # which is found in ENV['SERVER_NAME']
        begin
          TerrapopSetting.find_or_create_by(name: 'server_name') { |setting| setting.value = ENV['SERVER_NAME'] }
        rescue

        end
      end
    end

  end


  before

end



class TerrapopConfiguration

  include TerrapopConfigurationModule


  def self.[](key)
    @@configuration.dig(key)
  end

  def self.settings
    @@configuration.dig(APPLICATION, ENVIRONMENTS, Rails.env)
  end


  def self.inspect
    @@configuration.to_s
  end

end
