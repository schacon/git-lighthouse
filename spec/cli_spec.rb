require File.dirname(__FILE__) + "/spec_helper"
require 'stringio'

describe GitLighthouse::CLI do 
  include GitLighthouseSpecHelper
  
  before(:all) do 
    @path = setup_new_git_repo
    @orig_test_opts = test_opts
    @gitlh = GitLighthouse.open(@path, @orig_test_opts)
  end

  it "should list the tickets" do
    mock = (GitLighthouse::Lighthouse::Ticket)
    mock.should_receive(:created_at).and_return(Time.now())
    mock.should_receive(:number).and_return('1')
    mock.should_receive(:attachments_count).and_return('0')
    mock.should_receive(:title).and_return('test ticket')
    GitLighthouse::Lighthouse::Ticket.should_receive(:find).and_return([mock])
    
    Dir.chdir @path do
      ARGV = ['list']
      ob = output_buffer do 
        GitLighthouse::CLI.execute
      end
      ob[0].should match(/test ticket/)
    end
  end

  it "should show a ticket" do
    att = (GitLighthouse::Lighthouse::Attachment)
    att.should_receive(:name).and_return('att1.patch')
    
    mock = (GitLighthouse::Lighthouse::Ticket)
    mock.should_receive(:created_at).and_return(Time.now())
    mock.should_receive(:number).at_least(:once).and_return('1')
    mock.should_receive(:title).and_return('test ticket')
    mock.should_receive(:state).and_return('open')
    mock.should_receive(:tag).and_return('tag1 tag2')
    mock.should_receive(:body).and_return('this is a super cool ticket')
    mock.should_receive(:attachments).and_return([att])
    GitLighthouse::Lighthouse::Ticket.should_receive(:find).and_return([mock])
    
    Dir.chdir @path do
      ARGV = ['show', '1']
      ob = output_buffer do 
        GitLighthouse::CLI.execute
      end
      ob[0].should match(/this is a super cool ticket/)
    end
  end
  
  it "should be able to output a patch file to stdout" do
    ARGV = ['attachment', '1']
    ob = output_buffer do 
      GitLighthouse::CLI.execute
    end
    ob[0].should match(/Subject: [PATCH] test patch/)
  end

  it "should show a help message"

  it "should determine the difference between a format-patch and a diff patch"

  
  it "should apply a patch file as a new branch"

  it "should warn if config settings are not setup"
  
  it "should be able to push a patch replacement"
  
  it "should be able to push a patch addition"

  it "should be able to push a comment on a patch"
    
end