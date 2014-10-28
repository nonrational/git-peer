require "colored"
require "util"

module Git
  class PullRequestMerge

    MATCHER = /Merge pull request #([0-9]+) from [^\/]+\/(\S+)\s+(.*)$/

    def initialize(rugged_commit, octokit_remote)
      @commit = rugged_commit
      @remote = octokit_remote

      if match_result = MATCHER.match(commit.message)
        @pr_number = match_result[1]
        print_now '.'

        @pr = remote.rels[:pulls].get(uri: {number: pr_number}).data
        # https://developer.github.com/v3/pulls/
        @into = pr.base.ref
        @username = pr.user.login
        @merged_at = pr.merged_at
        @title = pr.title.strip
        @pr_url = pr.html_url
        @trello_url = pr.body[/https?:\/\/trello.com\S+/,0]
      else
        raise "#{rugged_commit} does not represent a GitHub PR Merge!"
      end
    end

    def to_s
      "##{pr_number}".blue + " (#{into}".red + " by " + "#{username}".green + " at #{merged_at}) ~> #{pr_url}\n\t#{title}\n\t#{trello_url}"
    end

    attr_reader :commit, :remote, :pr, :pr_number, :into, :username, :merged_at, :pr_url, :title, :trello_url
  end
end
