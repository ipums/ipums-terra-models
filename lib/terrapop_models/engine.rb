# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

module TerrapopModels

  class Engine < ::Rails::Engine
    isolate_namespace TerrapopModels

    config.autoload_paths << File.expand_path("../../../app/models", __FILE__)
    config.autoload_paths << File.expand_path("../../../app/models/nhgis", __FILE__)

    initializer :append_migrations do |app|
	    unless app.root.to_s.match root.to_s
		    config.paths["db/migrate"].expanded.each do |expanded_path|
			    app.config.paths["db/migrate"] << expanded_path
		    end
	    end
    end
    config.generators do |g|
	    g.test_framework :rspec
	    g.fixture_replacement :factory_girl, :dir => 'spec/factories'
    end
  end
end
