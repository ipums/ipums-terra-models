# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

# For area-level extracts, we include geog_level and geog_instance fields,

# but these aren't part of the request structure, which means that they need to be provided
# to the syntax generation system directly. This stub class provides a way to do that.
# data_type is expected to map to "integer" or "alphabetical"
class ExtractVariableStub
  attr_reader :mnemonic,:len,:label,:implied_decimal_places,:data_type,:categories
          
  def initialize(params)
    @mnemonic = params[:mnemonic] or raise "Must set mnemonic."
    @len = params[:len] or raise "Must set len."
    @label = params[:label] or raise "Must set label."
    @data_type = params[:data_type] or raise "Must set data_type."
    @categories = params[:categories] || []
    @implied_decimal_places = params[:implied_decimal_places] || 0
  end

end
