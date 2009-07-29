module GoogleBase
  class Product
    include DataMapper::Resource
    include GoogleBase::ProductProperties
  end
end
