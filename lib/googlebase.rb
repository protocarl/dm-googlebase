module GoogleBase
  dir = File.expand_path(File.join(File.dirname(__FILE__), 'googlebase'))

  require File.join(dir, 'adapter')

  autoload :Product,           File.join(dir, 'product')
  autoload :ProductProperties, File.join(dir, 'product_properties')
end
