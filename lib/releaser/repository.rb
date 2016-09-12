require 'english'

module Releaser
  class Repository
    attr_reader :path

    def initialize(path = '.')
      @path = File.expand_path(path)
      raise(Error, 'Unreadable path given') unless File.readable?(@path)
      raise(Error, 'Repository is not a directory') unless File.directory?(@path)
      raise(Error, 'Repository is not a github repository') unless git?
    end

    def git?
      File.directory?("#{@path}/.git")
    end

    def clean?
      committed = `git status -s`.chomp.strip.empty?
      pushed = `git log origin/master..HEAD`.chomp.strip.empty?

      return committed && pushed
    end

    def fetch_remote_tags
      `git fetch --tags`
      return $CHILD_STATUS.success?
    end

    class Error < StandardError; end
  end
end
