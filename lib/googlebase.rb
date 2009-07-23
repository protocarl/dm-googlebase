require "pathname"
require "rubygems"
require "extlib"

module GoogleBase
  dir = (Pathname(__FILE__).dirname.expand_path / 'googlebase').to_s

  autoload :Adapter, dir / 'adapter'
end
