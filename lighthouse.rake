# * rake patch:setup          # setup your token, TOKEN=XXXX..
#
# * rake patch:list           # list all open patch tickets
#
# * rake patch:show:ticket    # show patch ticket, include ID=XX
# * rake patch:show:attach    # outputs actual patch file, include ID=XX (and o...
# * rake patch:show:comments  # lists all comments on a ticket and adds up the +1s
#
# * rake patch:comment        # review a patch - comment and optionally +1 it (ID=XX)
#
# I would add a task to upload new attachments, but as far as I can tell, Lighthouse API
# has no way to do that.  I'll try to figure that out next, probably.


  
namespace :patch do
  
 desc 'review a patch - comment and optionally +1 it'
  task :comment => 'patch:requires' do

  end

  # possible future stuff :
  # desc 'create a new branch and apply ticket patch (run tests?)'  
  # desc 'diff patched branch'  
  # desc 'rebase patched branch'
  # desc 'create a new ticket with a patch'

end