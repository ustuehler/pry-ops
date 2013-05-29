Gem::Specification.new do |s|
  s.name        = 'pry-ops'
  s.version     = '0.0.0'
  s.date        = '2013-05-29'
  s.summary     = "Pry plugin for DevOps people"
  s.description = <<-EOS
  The pry-ops gem provides wrappers for commonly used services
  like GitHub, LDAP, Atlassian JIRA, Jenkins, and so on, allowing
  a "DevOps" oriented person to easily access the services they
  need to work with on a day-to-day basis in a programmatic way.

  Sometimes, such a service wrapper will just be a thin layer of
  documentation around some other gem which provides the actual
  implementation.  That's because sometimes a bit of documentation
  or a couple of examples are really all that we need.  Pry helps
  us to access and update that documentation from the command-line
  and to inspect unfamiliar APIs to see what's there and how they
  work when we get stuck.

  Gone should be the days where our hand-crafted tools consisted
  of poorly documented shell scripts that started life as fragile
  one-liners...  Let's build new, robust tools incrementally, as
  we find the need for them!
  EOS
  s.authors     = ["Uwe Stuehler"]
  s.email       = 'uwe@bsdx.de'
  s.files       = ["lib/pry-ops.rb"]
  s.homepage    = 'http://rubygems.org/gems/pry-ops'
end
