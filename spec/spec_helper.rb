require File.expand_path(File.dirname(__FILE__) + "/../lib/git-lighthouse")
require 'spec'
require 'fileutils'
require 'logger'

module GitLighthouseSpecHelper

  def setup_new_git_repo
    temp = Tempfile.new('gitrepo')
    p = temp.path
    temp.unlink
    Dir.mkdir(p)
    Dir.chdir(p) do
      g = Git.init
      g.config('lighthouse.account', 'rails')
      g.config('lighthouse.projectId', '8994')
      g.config('lighthouse.email', 'schacon@gmail.com')
      g.config('lighthouse.password', 'p00p')
    end
    p
  end

  def output_buffer
    std_out = StringIO.new()
    std_err = StringIO.new()
    $stdout = std_out
    $stderr = std_err

    yield

    $stdout = STDOUT
    $stderr = STDERR

    std_out.rewind()
    std_err.rewind()
    standard_out = std_out.read() 
    standard_error = std_err.read() 
    [standard_out, standard_error]
  end

  def test_opts
    logger = Logger.new(Tempfile.new('ticgit-log'))    
    { :logger => logger }
  end

  def new_file(name, contents)
    File.open(name, 'w') do |f|
      f.puts contents
    end
  end

end

  

##
# rSpec Hash additions.
#
# From 
#   * http://wincent.com/knowledge-base/Fixtures_considered_harmful%3F
#   * Neil Rahilly

class Hash

  ##
  # Filter keys out of a Hash.
  #
  #   { :a => 1, :b => 2, :c => 3 }.except(:a)
  #   => { :b => 2, :c => 3 }

  def except(*keys)
    self.reject { |k,v| keys.include?(k || k.to_sym) }
  end

  ##
  # Override some keys.
  #
  #   { :a => 1, :b => 2, :c => 3 }.with(:a => 4)
  #   => { :a => 4, :b => 2, :c => 3 }
  
  def with(overrides = {})
    self.merge overrides
  end

  ##
  # Returns a Hash with only the pairs identified by +keys+.
  #
  #   { :a => 1, :b => 2, :c => 3 }.only(:a)
  #   => { :a => 1 }
  
  def only(*keys)
    self.reject { |k,v| !keys.include?(k || k.to_sym) }
  end

end
