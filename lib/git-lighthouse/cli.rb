require 'git-lighthouse'
require 'optparse'

# used Cap as a model for this - thanks Jamis

module GitLighthouse
  class CLI
    # The array of (unparsed) command-line options
    attr_reader :action, :options, :args, :tic

    def self.execute
      parse(ARGV).execute!
    end
    
    def self.parse(args)
      cli = new(args)
      cli.parse_options!
      cli
    end

    def initialize(args)
      @args = args.dup
      @lh = GitLighthouse.open('.')
    end    
    
    def execute!
      case action
      when 'list':
        handle_ticket_list
      when 'show'
        handle_ticket_show
      when 'comments'
        handle_ticket_comments
      when 'checkout', 'co'
        handle_ticket_checkout
      when 'attachment'
        handle_ticket_attachment
      when 'apply'
        handle_ticket_apply
      when 'comment'
        handle_ticket_comment
      when 'recent'
        handle_ticket_recent
      else
        puts 'not a command'
      end
    end

    def handle_ticket_recent
      #tic.ticket_recent(ARGV[1]).each do |commit|
      #  puts commit.sha[0, 7] + "  " + commit.date.strftime("%m/%d %H:%M") + "\t" + commit.message
      #end
    end
    
    def handle_ticket_comment      
      #tid = nil
      #tid = ARGV[1].chomp if ARGV[1]
      #if(m = options[:message])
      #  tic.ticket_comment(m, tid)
      #elsif(f = options[:file])
      #  tic.ticket_comment(File.read(options[:file]), tid)
      #else
      #  if message = get_editor_message
      #    tic.ticket_comment(message.join(''), tid)
      #  end
      #end
    end
    
    def handle_ticket_checkout
      tid = ARGV[1].chomp rescue nil
      attId = ARGV[2].chomp rescue nil
      if new_branch = @lh.ticket_checkout(tid, attId)
        puts "Patch successfully applied - now in branch #{new_branch}"
      end
    end
        
    def handle_ticket_list
      tickets = []
      puts ['Date', 'Num', 'Attch', 'Title'].join("\t")
      @lh.get_patch_tickets.each do |tic|
        tickets << [tic.created_at.strftime("%m/%d"), tic.number, tic.attachments_count, tic.title[0, 70]]
      end
      tickets.sort! { |a, b| a[1] <=> b[1] }
      puts tickets.map { |t| t.join("\t") }.join("\n") 
    end
    
    ## SHOW TICKETS ##
    
    def handle_ticket_show
      tid = ARGV[1].chomp rescue nil
      
      if tic = @lh.get_ticket(tid)
        tic_url = @lh.get_url(tic)
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
        counter = 0
        tic.attachments(tic_url).each do |att|
          counter += 1
          puts '  ' + counter.to_s + ' : ' + att.name
        end
      end
    end
    
    # outputs actual patch file
    def handle_ticket_attachment
      tid = ARGV[1].chomp rescue nil
      attId = ARGV[2].chomp rescue nil
      puts @lh.get_attachment_data(tid, attId)
    end
    
    def handle_ticket_comments
      tid = ARGV[1].chomp rescue nil
      if tic = @lh.get_ticket(tid)
        tic_url = @lh.get_url(tic)     
        puts 
        puts 'Title   : ' + tic.title
        puts 'URL     : ' + tic_url        
        puts
        puts '-- Comments --'
        puts

        doc = Hpricot(open(@lh.get_xml_url(tid)))
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
    

    
    def get_editor_message(message_file = nil)
      message_file = Tempfile.new('ticgit_message').path if !message_file
      
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
    
    def parse_options! #:nodoc:      
      if args.empty?
        warn "Please specify at least one action to execute:"
        puts "  list - list patch tickets in lighthouse"
        puts "  show (id) - show ticket detail "
        puts "  comments (id) - shows all comments on this ticket"
        puts "  attachment (ticket_id) [attachment number] - output patch to stdout"
        puts "  checkout (id) - create a new branch and apply ticket to it"
        #puts "  apply (id) - apply ticket to current branch"
        #puts "  push (id) - create new patch file and push to ticket"
        #puts "  comment (id) - add comment to ticket"
        exit
      end

      @action = args.first
    end
    
    
    def just(value, size, side = 'l')
      value = value.to_s
      if value.size > size
        value = value[0, size]
      end
      if side == 'r'
        return value.rjust(size)
      else
        return value.ljust(size)
      end
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
    
  end
end