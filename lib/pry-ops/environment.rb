require 'pry-ops'

class PryOps::Environment
  include PryOps::Resource

  property :name, String, :key => true, :required => true

  has n, :children, :model => 'PryOps::Environment', :child_key => [ :parent_name ]
  belongs_to :parent, :model => 'PryOps::Environment', :child_key => [ :parent_name ]

  has n, :services
end
