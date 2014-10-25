#!/usr/bin/env ruby
require "octokit"
require "rugged"

class Rugged::Commit

  def merge_regex
    @merge_regex ||= /Merge pull request #([0-9]+) from [^\/]+\/(\S+)\s+(.*)$/
  end

  def pr_merge?
    merge_regex.match(self.message)
  end

  def to_pr_str
    "#{pr_number} | #{pr_branch_name} : #{pr_description}"
  end

  def pr_number
    pr_merge?[1]
  end

  def pr_branch_name
    pr_merge?[2]
  end

  def pr_description
    pr_merge?[3]
  end
end

class GitFern

  def initialize
    @repo = Rugged::Repository.discover("/Users/norton/src/better-core")
    @hub = Octokit::Client.new(:access_token => ENV['GITHUB_API_TOKEN'])
    remote_path = /https?:\/\/(\.?\w+)+\/([^?]+)/.match(repo.branches.find { |b| b.canonical_name == repo.head.canonical_name }.remote.url)[2]
    @remote = @hub.repo(remote_path)
  end

  def tag_by_name(tag_name)
    repo.tags.find {|tag| tag.name == tag_name }
  end

  def pr_for_commit(commit)
    pr_number = commit.pr_number
    pr = remote.rels[:pulls].get(uri: {number: pr_number}).data

    title = pr.title.strip
    body = pr.body.strip
    url = pr.html_url
    trello = body[/https?:\/\/trello.com\S+/,0]
    "##{pr_number} #{title} #{trello}"
  end

  def merges_between(from_tag_name, to_tag_name)

    from = tag_by_name from_tag_name
    to = tag_by_name to_tag_name

    if !(from and to)
      raise "#{from_tag_name}...#{to_tag_name} is invalid"
    end

    walker = Rugged::Walker.new(repo)

    walker.hide(from.target)
    walker.push(to.target)

    walker.find_all { |commit| commit.pr_merge? }
  end

  attr_reader :repo, :hub, :remote
end

fern = GitFern.new
fern.merges_between("2.8.16", "2.8.17").each { |m| puts fern.pr_for_commit(m) }
