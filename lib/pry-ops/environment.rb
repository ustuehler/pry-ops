require 'pry-ops'

class PryOps::Environment
  include PryOps::Resource

  property :name, String, :key => true, :required => true

  has n, :services
end
