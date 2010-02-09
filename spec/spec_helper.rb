require 'rubygems'
 
def smart_require(lib_name, gem_name, gem_version = '>= 0.0.0')
  begin
    require lib_name if lib_name
  rescue LoadError
    if gem_name
      gem gem_name, gem_version
      require lib_name if lib_name
    end
  end
end
 
smart_require 'spec', 'spec', '>= 1.2.6'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/lamer'))