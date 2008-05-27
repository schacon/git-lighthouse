Gem::Specification.new do |s|
    s.platform  =   Gem::Platform::RUBY
    s.name      =   "git-lighthouse"
    s.version   =   "0.1.0"
    s.date      =   "2008-05-27"
    s.author    =   "Scott Chacon"
    s.email     =   "schacon@gmail.com"
    s.summary   =   "Provides command line access to a Lighthouse ticketing system for a git based software package."
    s.files     =   ["bin/git-lh", "lib/git-lighthouse/base.rb", "lib/git-lighthouse/cli.rb", "lib/git-lighthouse/lighthouse.rb", "lib/git-lighthouse/version.rb", "lib/git-lighthouse.rb", "LICENSE", "README.txt", "spec/cli_spec.rb", "spec/spec_helper.rb"]
    
    s.bindir = 'bin'
    s.executables << "git-lh"
    s.homepage = "http://github/schacon/git-lighthouse"

    s.add_dependency('git', [">= 1.0.7"])

    s.require_path  =   "lib"
end
