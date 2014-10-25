#!/usr/bin/env ruby
require "github_api"
require "rugged"

class Rugged::Commit
  def merge_regex
    @merge_regex ||= /Merge pull request #([0-9]+) from [^\/]+\/(\S+)\s+(.*)$/
  end

  def pr_merge?
    merge_regex.match(self.message)
  end

  def to_pr_str
    m = merge_regex.match(self.message)
    "#{m[1]} : #{m[2]} : #{m[3][0,35]}"
  end
end

class GitFern
  def repo
    @repo ||= Rugged::Repository.discover("/Users/norton/src/better-core")
  end

  def tag_by_name(tag_name)
    repo.tags.find {|tag| tag.name == tag_name }
  end

  def pr_by_number(pr_number)

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

    walker.find_all { |commit| commit.pr_merge? }.each { |m| puts m.to_pr_str }
  end
end

GitFern.new.merges_between("2.8.9", "2.8.10")
