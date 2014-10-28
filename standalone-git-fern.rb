#!/usr/bin/env ruby

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git/fern'

# TODO: Use ARGV / Thor
# git fern <tag>..HEAD #DEFAULT
Git::Fern.new("/Users/norton/src/better-core", "master").print("2.8.18.9")


