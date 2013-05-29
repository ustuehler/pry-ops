$:.unshift File.dirname(__FILE__) + '/lib'

require 'pry-ops'

# http://stackoverflow.com/questions/13617888/how-can-i-cd-to-a-class-object-in-a-pryrc-file
Pry.config.hooks.add_hook(:before_session, :set_context) do |a, b, pry|
  if self.class == Object and self.to_s == "main"
    pry.input = StringIO.new("cd PryOps")
  end
  Pry.config.hooks.delete_hook(:before_session, :set_context)
end
