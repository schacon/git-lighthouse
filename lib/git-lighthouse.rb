$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'yaml'
require 'active_resource'
require 'active_support'
require 'hpricot'
require 'open-uri'
require 'pp'
require 'git'

require 'git-lighthouse/base'
require 'git-lighthouse/lighthouse'
require 'git-lighthouse/cli'

module GitLighthouse

  # options
  #   :logger => Logger.new(STDOUT)
  def self.open(git_dir, options = {})
    Base.new(git_dir, options)
  end

end