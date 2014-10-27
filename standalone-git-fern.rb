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
require "pp"

class Rugged::Commit
  def merge_regex
    @merge_regex ||= /Merge pull request #([0-9]+) from [^\/]+\/(\S+)\s+(.*)$/
  end

  def pr_merge?
    merge_regex.match(self.message)
  end

  def pr_number
    pr_merge?[1]
  end
end

class GitFern

  def initialize
    begin
      @repo = Rugged::Repository.discover("/Users/norton/src/better-core")
      original_branch_name = repo.head.canonical_name
      @repo.checkout('master')
      remote_path = /https?:\/\/(\.?\w+)+\/([^?]+)/.match(repo.branches.find { |b| b.canonical_name == repo.head.canonical_name }.remote.url)[2]

      @hub = Octokit::Client.new(:access_token => ENV['GITHUB_API_TOKEN'])
      @remote = @hub.repo(remote_path)
    ensure
      @repo.checkout(original_branch_name)
    end
  end

  def tag_by_name(tag_name)
    repo.tags.find {|tag| tag.name == tag_name }
  end

  def branch_by_name(ref_name)
    raise "UNIMPLEMENTED"
  end

  def commit_by_hash(short_hash)
    raise "UNIMPLEMENTED"
  end

  def pr_for_commit(commit)
    pr_number = commit.pr_number

    # https://developer.github.com/v3/pulls/
    pr = remote.rels[:pulls].get(uri: {number: pr_number}).data

    into = case pr.base.ref
      when 'master'
        pr.base.ref.red
      when 'stage'
        pr.base.ref.yellow
      when 'develop'
        pr.base.ref.green
    end

    # TODO ERB these vars up into HTML
    username = pr.user.login
    title = pr.title.strip
    body = pr.body.strip
    url = pr.html_url
    trello = body[/https?:\/\/trello.com\S+/,0]

    "##{pr_number}".blue + " (#{into},#{username}) #{title}\n\t#{url}\n\t#{trello}"
  end

  def merged_to_here(from_tag_name)
    merges_between_targets(tag_by_name(from_tag_name).target, repo.head.target)
  end

  def merges_between_tags(from_tag_name, to_tag_name)
    merges_between_targets(tag_by_name from_tag_name, tag_by_name to_tag_name)
  end


  def merges_between_targets(from_target, to_target)
    if !(from_target and to_target)
      raise "#{from_tag_name}...#{to_tag_name} is invalid"
    end

    walker = Rugged::Walker.new(repo)
    walker.hide(from_target)
    walker.push(to_target)
    walker.find_all { |commit| commit.pr_merge? }
  end

  attr_reader :repo, :hub, :remote
end

# TODO: Use ARGV / Thor
# git fern <tag>..HEAD #DEFAULT
fern = GitFern.new
from_tag_name="2.8.18.9"
merges = fern.merged_to_here(from_tag_name)
puts "Found #{merges.size} merges between #{from_tag_name}..HEAD"
merges.each { |m| puts fern.pr_for_commit(m) }
