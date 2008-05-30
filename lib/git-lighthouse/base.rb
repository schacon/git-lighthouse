module GitLighthouse
  class Base
    
    attr_reader :lh_url, :account, :projectId, :token, :email, :password
    
    def initialize(working_dir, options = {})
      #options = {:log => Logger.new(STDOUT)}
      @git = Git.init(working_dir, options)
      
      @account = @git.config('lighthouse.account')
      @projectId = @git.config('lighthouse.projectId')
      @token = @git.config('lighthouse.token')
      @email = @git.config('lighthouse.email')
      @password = @git.config('lighthouse.password')
      @lh_url = "http://#{@account}.lighthouseapp.com"

      Lighthouse.account = @account
      Lighthouse.token = @token if @token
      Lighthouse.email = @email if @email
      Lighthouse.password = @password if @password
    end

    
    def get_project
      Lighthouse::Project.find(@projectId)
    end

    def get_patch_tickets
      ts = Lighthouse::Ticket.find(:all, :params => { :project_id => @projectId, 
                                              :q => "state:open tagged:patch" })  
    end
    
    def ticket_checkout(tid, attId)
      # stash current changes
      if @git.branch.stashes.save('applying ticket patch')
        puts 'stashed changes'
      end
      
      ticket_handle = 'ticket' + tid.to_s
      if attId
        ticket_handle += '-' + attId.to_s
      end
      
      tic = get_ticket(tid)
      tic.created_at
      
      # last commit before this date
      base_commit = @git.log(1).until(tic.created_at.to_s).first rescue nil
      if !base_commit
        base_commit = @git.log(1).first
      end
      
      puts "nearest commit: " + base_commit.sha
      
      if base_commit
        patch = self.get_attachment_data(tid, attId)
        patch_file = Tempfile.new('patch')
        patch_file.write(patch)
        patch_file.close
        path = patch_file.path
        
        begin
          # create and checkout new branch based on recent as of ticket
          @git.checkout(base_commit, :new_branch => ticket_handle)
          
          if patch.match(/From [a-f0-9]{40}/)
            @git.apply_mail(path)
          else
            @git.apply(path)
          end
        rescue Git::GitExecuteError => e
          puts 'Git Error : ' + e.message
          return false
        end
      else
        puts 'could not find commit before this ticket date, oddly..'
        return false
      end
      return ticket_handle
    end

    def get_url(tic)
      @lh_url + "/projects/#{@projectId}/tickets/#{tic.number}"
    end

    def get_xml_url(ticket_id)
      @lh_url + "/projects/#{@projectId}/tickets/#{ticket_id}.xml"
    end

    def get_ticket(ticket_id)
      if ticket_id
        tickets = get_patch_tickets  # cant figure out how to get a specific ticket
        if t = tickets.select { |t| t.number.to_s == ticket_id }
          if tic = t.first
            return tic
          end
        end
      end
      return false    
    end
    
    def get_attachment_data(tid, attId)
      output = ''
      if tic = get_ticket(tid)
        doc = Hpricot(open(get_url(tic)))
        urls = []
        (doc/"ul.attachments"/:li/:ins/:h4/:a).each do |t| 
          urls << @lh_url + t['href']
        end      
        idx = ((urls.size > 1) && (attId)) ? attId.to_i - 1 : 0
        output = open(urls[idx]).read if urls[idx]
      end
      output
    end
    
  end
end