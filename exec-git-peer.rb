#!/usr/bin/env ruby

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git/peer'

# TODO: Use ARGV / Thor
# git peer <tag>..HEAD #DEFAULT
peer = Git::Peer.new("/Users/norton/src/better-core", "master")
peer.run("2.8.18.11")
puts peer.render(File.read('lib/git/templates/report.erb'))
# peer.to_stdout
