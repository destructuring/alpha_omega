require 'tempfile'

Capistrano::Configuration.instance(:must_exist).load do |config|
  namespace :deploy do
    namespace :notify do
      task :default do
        if $deploy["notify"]
          unless skip_notifications
            # run notifications here
          end

          email if $deploy["notify"].member? "email"
        end
      end

      task :email do
        tmp_notify = Tempfile.new('email')
        tmp_notify.write notify_message
        tmp_notify.close
        run_locally "cat '#{tmp_notify.path}' | mail -s '#{notify_message_abbr}' #{$deploy["notify"]["email"]["recipients"].join(" ")}"
        tmp_notify.unlink
      end

      def map_sha_tag rev
        tag = %x(git show-ref | grep '^#{rev} refs/tags/' | cut -d/ -f3).chomp
        tag.empty? ? rev : tag
      end

      def public_git_url url
        url.sub("git@github.com:","https://github.com/").sub(/\.git$/,'')
      end

      def notify_message
        summary = "#{public_git_url repository}/compare/#{map_sha_tag cmp_previous_revision}...#{map_sha_tag cmp_current_revision}"

        "#{ENV['_AO_DEPLOYER']} deployed #{application} to #{ENV['_AO_ARGS']} (#{dna['app_env']}): #{ENV['FLAGS_tag']}" +
        "\n\nSummary:\n\n" + summary + 
        "\n\nLog:\n\n" + full_log
      end 

      def notify_message_abbr
        "#{ENV['_AO_DEPLOYER']} deployed #{application} to #{ENV['_AO_ARGS']} (#{dna['app_env']}): #{ENV['FLAGS_tag']}"
      end 
    end
  end

  after "deploy:restart", "deploy:notify"
end
