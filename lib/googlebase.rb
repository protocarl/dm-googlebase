require "pathname"
require "rubygems"
require "extlib"

module GoogleBase
  dir = (Pathname(__FILE__).dirname.expand_path / 'googlebase').to_s

  require dir / 'adapter'

  autoload :Product, dir / 'product'
end
