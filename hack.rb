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
  def repo
    @repo ||= Rugged::Repository.discover("/Users/norton/src/better-core")
  end

  def tag_by_name(tag_name)
    repo.tags.find {|tag| tag.name == tag_name }
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
end

GitFern.new.merges_between("2.6.1", "2.6.2").each { |m| puts m.to_pr_str }
