# frozen_string_literal: true
require "inspec/resource"

module InspecPlugins::PodmanResources
  # This class will provide the actual CLI implementation.
  # Its superclass is provided by another call to Inspec.plugin,
  # this time with two args.  The first arg specifies we are requesting
  # version 2 of the Plugins API.  The second says we are making a Resource
  # Pack plugin component, so please make available any DSL needed
  # for that.
  class ResourcePack < Inspec.plugin(2, :resource_pack)
    # TBD
    # load_timing :early  <-- isn't that implicit in the rewuire statements
    # train relationship declarations?  <-- that should be in the gemspec
  end
end
