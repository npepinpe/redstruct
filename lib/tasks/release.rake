require 'releaser/repository'

repo = Releaser::Repository.new
logger = Releaser::Logger.new($stdout)

namespace :releaser do
  namespace :repo do
    desc 'Updates README, CHANGELOG, tags the release'
    task :release do
      unless repo.clean?
        logger.error('Uncommitted/unpushed changes detected; aborting')
        exit(-1)
      end

      repo.fetch_remote_tags

      tasks = %i[update_version update_readme update_changelog update_tags]
      tasks.each do |task|
        Rake::Task[task].invoke
      end

      repo.synchronize
    end

    desc 'Updates the current version'
    task :update_version do
    end

    desc 'Updates the README'
    task :update_readme do
    end

    desc 'Updates the CHANGELOG'
    task :update_changelog do
    end

    desc 'Tags release'
    task :tag do
    end
  end

  namespace :gem do
    desc 'Ensures repo version exists, builds the gem, and pushes it'
    task :release do
    end
  end
end
