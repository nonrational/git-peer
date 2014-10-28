#!/usr/bin/env ruby

#  _                _         _   _             _
# | |__   __ _  ___| | ____ _| |_| |_ __ _  ___| | __
# | '_ \ / _` |/ __| |/ / _` | __| __/ _` |/ __| |/ /
# | | | | (_| | (__|   < (_| | |_| || (_| | (__|   <
# |_| |_|\__,_|\___|_|\_\__,_|\__|\__\__,_|\___|_|\_\
# hacked-in functionality to wrap in Git::Fern
#

require "colored"
require "octokit"
require "rugged"

class PullRequestMerge

  MATCHER = /Merge pull request #([0-9]+) from [^\/]+\/(\S+)\s+(.*)$/

  def initialize(rugged_commit, octokit_remote)
    @commit = rugged_commit
    @remote = octokit_remote

    if match_result = MATCHER.match(commit.message)
      @pr_number = match_result[1]
      puts "Fetching #{pr_number} ..."

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
    # TODO ERB these vars up into HTML
    "##{pr_number}".blue + " (#{into}".red + " by " + "#{username}".green + " at #{merged_at}) ~> #{pr_url}\n\t#{title}\n\t#{trello_url}"
  end

  attr_reader :commit, :remote, :pr, :pr_number, :into, :username, :merged_at, :pr_url, :title, :trello_url
end

class GitFern

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

  def print(from_tag_name)
    merges = merged_to_here(from_tag_name)
    merges.each { |m| puts m }
    puts "Found #{merges.size} PR merges between #{from_tag_name}..HEAD"
  end

  def tag_by_name(tag_name)
    repo.tags.find {|tag| tag.name == tag_name }
  end

  def merged_to_here(from_tag_name)
    merges_between_targets(tag_by_name(from_tag_name).target, repo.head.target)
  end

  def merges_between_tags(from_tag_name, to_tag_name)
    merges_between_targets(tag_by_name(from_tag_name), tag_by_name(to_tag_name))
  end

  def merges_between_targets(from_target, to_target)
    if !(from_target and to_target)
      raise "#{from_tag_name}...#{to_tag_name} is invalid"
    end

    walker = Rugged::Walker.new(repo)
    walker.hide(from_target)
    walker.push(to_target)
    walker.find_all { |commit| PullRequestMerge::MATCHER.match(commit.message) }.map { |rc| PullRequestMerge.new(rc, remote) }
  end

  attr_reader :repo, :hub, :remote
end

# TODO: Use ARGV / Thor
# git fern <tag>..HEAD #DEFAULT
GitFern.new("/Users/norton/src/better-core", "master").print("2.8.18.9")


