module GitLighthouse
  class Base
    
    attr_reader :lh_url, :account, :projectId, :token, :email, :password
    
    def initialize(working_dir, options = {})
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
    
  end
end