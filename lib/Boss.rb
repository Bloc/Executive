require "boss/version"
require 'colorize'

module Boss
  class << self
    def start
      @foreman_pid = Process.spawn("foreman start")
    end
    
    def restart
      puts "\tRestarting Foreman".blue
      Process.kill "TERM", @foreman_pid
      start
    end
  end

  module Development
    def self.ensure_system_call(command)
      unless system(command)
        puts %Q(>> Error Running: "#{command}").red
        exit
      end
    end

    def self.deploy
      if File.exists?(".deployed_revision")
        deployed_revision   = File.read(".deployed_revision").chomp
        migrations_present  = (`git log #{deployed_revision}..HEAD -- db/migrate/` != "")
        seeds_changed       = (`git log #{deployed_revision}..HEAD -- db/fixtures/` != "")
        env_changed         = (`git log #{deployed_revision}..HEAD -- .env` != "")
      else
        migrations_present  = true
        seeds_changed       = true
        env_changed         = true
      end

      puts ">> Deploying Development".green
      if migrations_present
        puts ">> Running Migrations".green
        ensure_system_call("rake db:migrate")
      else
        puts ">> Skipping Migrations".yellow
      end

      if seeds_changed
        puts ">> Updating DB Seeds".green
        ensure_system_call("rake db:seed_fu")
      else
        puts ">> Skipping DB Seeding".yellow
      end

      if env_changed
        puts ">> Restarting Foreman".green

        begin
          foreman_pid = `ps aux | grep '[s]cript/start'`.split("\n").first.split(" ")[1]
          Process.kill "HUP", foreman_pid.to_i
        rescue NoMethodError => e
          puts "Foreman isn't running. Run script/start.".red
        end
      else
        puts ">> Skipping Foreman Restart".yellow
      end

      File.open(".deployed_revision", "w+") { |f| f << `git rev-parse HEAD` }
      puts ">> Recorded Deployed Revision".green
    end
  end

  module Production
    def self.ensure_system_call(command)
      unless system(command)
        puts %Q(>> Error Running: "#{command}").red
        exit
      end
    end

    def self.deploy
      app = "bloc-workshop"
      remote = "heroku"

      puts              ">> Deploying Production".green

      if `git log origin/master..HEAD` != ""
        puts                ">> Pushing to Github".green
        ensure_system_call  %Q(git push origin master)
      end

      migrations_present = (`git log heroku/master..HEAD -- db/migrate/` != "")

      if migrations_present
        puts                ">> Turning On Maintenance Mode".green
        ensure_system_call  "heroku maintenance:on --app #{app}"
      end

      puts                ">> Deploying to Heroku".green
      ensure_system_call  "git push #{remote} master"

      if migrations_present
        ensure_system_call  "heroku run rake db:migrate --app #{app}"
      end

      if migrations_present
        puts                ">> Turning Off Maintenance Mode".green
        ensure_system_call  "heroku maintenance:off --app #{app}"
      end

      # Notify Airbrake
      system("rake airbrake:deploy TO=production")
    end
  end
end
