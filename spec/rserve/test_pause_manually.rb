#!/usr/bin/ruby

require 'rserve/simpler/R'
require 'curses'

ARGV.push(*%w(one two three))
#ARGF.push(*%w(one two three))

R >> "plot(c(1,2,3), c(1,2,3))"
R.pause

R >> "plot(c(8,9,10,11,20), c(1,2,3,0,50))"
R.pause

R >> "plot(c(8,9,10), c(1,2,3), type='l')"
R.pause


