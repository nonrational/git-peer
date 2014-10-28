require "octokit"
require "rugged"
require "git/pull_request_merge"
require "util"
require "erb"

module Git
  class Peer
    def initialize(local_repo_dir, default_branch)
      @repo = Rugged::Repository.discover(local_repo_dir)
      original_branch_name = repo.head.canonical_name
      @repo.checkout(default_branch)

      remote_path = /https?:\/\/(\.?\w+)+\/([^?]+)/.match(repo.branches.find { |b| b.canonical_name == repo.head.canonical_name }.remote.url)[2]

      @hub = Octokit::Client.new(:access_token => ENV['GITHUB_API_TOKEN'])
      @remote = @hub.repo(remote_path)
    ensure
      @repo.checkout(original_branch_name)
    end

    def run(from_tag_name)
      @from_tag_name = from_tag_name
      print_now "Fetching"
      @merges = merged_to_here(from_tag_name)
      puts ""
    end

    def to_stdout
      merges.each { |m| puts m }
      puts "Found #{merges.size} PR merges between #{from_tag_name}..HEAD"
    end

    # def save(file)
    #   renderer = ERB.new('report.erb', self)
    #   # File.open(file, "w+") { |f| f.write(renderer) }
    # end

    def render(template)
      ERB.new(template).result(binding)
    end

    def tag_by_name(tag_name)
      repo.tags.find {|tag| tag.name == tag_name }
    end

    def merged_to_here(from_tag_name)
      merges_between_targets(tag_by_name(from_tag_name).target, repo.head.target)
    end

    def merges_between_targets(from_target, to_target)
      if !(from_target and to_target)
        raise "#{from_tag_name}...#{to_tag_name} is invalid"
      end

      walker = Rugged::Walker.new(repo)
      walker.hide(from_target)
      walker.push(to_target)

      walker.find_all { |commit| Git::PullRequestMerge::MATCHER.match(commit.message) }.map { |rc| Git::PullRequestMerge.new(rc, remote) }
    end

    attr_reader :repo, :hub, :remote, :merges, :from_tag_name

    private

  end
end
