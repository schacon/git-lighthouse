$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'yaml'
require 'active_resource'
require 'active_support'
require 'hpricot'
require 'open-uri'
require 'pp'
require 'git'

require 'lighthouse'
require 'git-lighthouse/cli'

module GitLighthouse
  
  def show_ticket
    setup_env
    
    if tic = get_ticket(ENV['ID'])
      tic_url = get_url(tic)
      puts
      puts 'Title   : ' + tic.title
      puts 'Number  : ' + tic.number.to_s
      puts
      puts 'URL     : ' + tic_url
      puts 'Created : ' + tic.created_at.to_s
      puts 'State   : ' + tic.state
      puts 'Tags    : ' + tic.tag
      puts
      puts word_wrap(tic.body)
      puts
      puts '-- Attachments --'
      puts
    
      # load the url, because we have to scrape the attachments
      doc = Hpricot(open(tic_url))
      counter = 0
      (doc/"ul.attachments"/:li/:ins/:h4/:a).each do |t| 
        counter += 1
        puts '  ' + counter.to_s + ' : ' + t['href'].split('/').last
      end
    end
  end
  
  # outputs actual patch file, include ID=XX 
  # (and optionally NUMBER=XX if more than 1)
  def show_attach
    setup_env
    
    if tic = get_ticket(ENV['ID'])
      doc = Hpricot(open(get_url(tic)))
      urls = []
      (doc/"ul.attachments"/:li/:ins/:h4/:a).each do |t| 
        urls << LH_URL + t['href']
      end      
      idx = ((urls.size > 1) && (ENV['NUMBER'])) ? ENV['NUMBER'].to_i - 1 : 0
      puts open(urls[idx]).read if urls[idx]
    end
  end
  
  def show_comments
    setup_env
    
    if tic = get_ticket(ENV['ID'])     
      puts 
      puts 'Title   : ' + tic.title
      puts
      puts '-- Comments --'
      puts
      
      doc = Hpricot(open(get_xml_url(ENV['ID'])))
      (doc/"versions > version").each do |comment|
        #puts (comment/'updated-at').first.inner_html rescue nil
        puts word_wrap((comment/:body).inner_html) rescue nil
        puts '---'
      end
      
      plus_ones = 0
      (doc/"versions > version > body").each do |comment|
        if comment.inner_html.match(/\+1/)
          plus_ones += 1
        end
      end
      puts "PLUSONES: " + plus_ones.to_s
    end
  end
  
  def comment
    setup_env
    
    if tic = get_ticket(ENV['ID'])
      message_file = Tempfile.new('rails_message')
      message_file.write comment_message()
      message_file.close

      if ed_comment = get_editor_message(message_file.path)
        tic.body = ed_comment.to_s
        if tic.save
          puts "Comment saved"
          
          doc = Hpricot(open(get_xml_url(ENV['ID'])))
          plus_ones = 0
          (doc/"versions > version > body").each do |comment|
            if comment.inner_html.match(/\+1/)
              plus_ones += 1
            end
          end
          if plus_ones > 2
            # we have three, lets tag it
            tic.tags << 'verified'
            tic.save
          end
        end
      end
    end
  end
  
  def list
    setup_env
    
    tickets = []
    puts ['Date', 'Num', 'Attch', 'Title'].join("\t")
    get_patch_tickets.each do |tic|
      tickets << [tic.created_at.strftime("%m/%d"), tic.number, tic.attachments_count, tic.title[0, 70]]
    end
    tickets.sort! { |a, b| a[1] <=> b[1] }
    puts tickets.map { |t| t.join("\t") }.join("\n") 
  end
  
  def comment_message
  m = "
  # Comment on the lighthouse ticket indicating your approval. Your comment 
  # should indicate that you like the change and what you like about it. 
  # Something like:
  #
  # '+1. I like the way you've restructured that code in generate_finder_sql, 
  #   much nicer. The tests look good too.'
  #
  # If your comment simply says +1, then odds are other reviewers aren't 
  #  going to take it too seriously. Show that you took the time to review 
  #  the patch. "
  end

  def setup_env
    LH_URL = "http://rails.lighthouseapp.com"
    RAILS_PROJECT_ID = 8994
    
    Lighthouse.account = 'rails'
    #Lighthouse.account = 'chacon'
    if File.exists?(CONFIG_FILE)
      config = YAML::load(File.open(CONFIG_FILE))
      Lighthouse.token = config['token']
    end
  end

  def get_project
    Lighthouse::Project.find(RAILS_PROJECT_ID)
  end

  def get_patch_tickets
    ts = Lighthouse::Ticket.find(:all, :params => { :project_id => RAILS_PROJECT_ID, 
                                            :q => "state:open tagged:patch" })  
  end

  def get_url(tic)
    LH_URL + "/projects/#{RAILS_PROJECT_ID}/tickets/#{tic.number}"
  end

  def get_xml_url(ticket_id)
    LH_URL + "/projects/#{RAILS_PROJECT_ID}/tickets/#{ticket_id}.xml"
  end

  def word_wrap(text, line_width = 80, line_height = 15)
    block = text.split("\n").collect do |line|
      '   ' + ((line.length > line_width) ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "    \\1\n").strip : line)
    end * "\n"
    block_lines = block.split("\n")
    if block_lines.size > line_height
      block_lines[0, line_height].join("\n") + "\n ..."
    else
      block_lines.join("\n")
    end
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

  def get_editor_message(message_file = nil)
    message_file = Tempfile.new('rails_message').path if !message_file

    editor = ENV["EDITOR"] || 'vim'
    system("#{editor} #{message_file}");
    message = File.readlines(message_file)
    message = message.select { |line| line[0, 1] != '#' } # removing comments   
    if message.empty?
      return false
    else
      return message
    end   
  end
  
end