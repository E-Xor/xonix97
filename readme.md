# Xonix97

Based on the Xonix32 introduced in 1997 for Windows 95 and inspired by the original DOS Xonix.

The main difference between Xonix32 and original Xonix is moving orange lines that paint back the field.

This version also allows red line to selve-intersect. I think it was not allowed originally to keep Flood Fill faster.

## Why

To learn:
1. Gaming frameworks for Ruby
1. Concepts behind creating games
1. Flood Fill algorithm
1. Bresenham's Line algorithm
1. Generate binaries from Ruby
1. Make Mac/OS X app from Ruby binary

Despite visual simplicity this game provides an opportunity to learn and experiment with a couple of pretty cool algorithms.

## The real story

I actually attempted to do it when I was 18-20 yo and I thought it's way too hard and my solution is terrible. Looking back I was actually pretty good despite making some not very efficient decisions.

This time I decided to spend more time on reverse-engineering the game instead of just coming up with my own solutions first. I knew that source code of an older Xonix32 version is available, had to dig a little on the Internet. Also had to find and install Windows98 and Visual C++ 6.0 in a virtual machine.

Ability to play around with the code helped a lot to understand the approach as well as reproduce the game more closely.

## What's up with the folder structure?

Ruby code goes into binary and binary goes into Mac/OS X App. Currently using rubyc for binary creating and Platypus for the app. That folder structure makes it easier to manipulate all these transformations.

## Gosu

```
brew install sdl2
gem install gosu # In Gemfile
```

## Ruby Packer

```
brew install squashfs
# Install Command Line Tools from https://developer.apple.com/download/more/
curl -L http://enclose.io/rubyc/rubyc-darwin-x64.gz | gunzip > rubyc
chmod +x rubyc
./rubyc --tmpdir=/Users/maksim/Downloads/tmp --output=Xonix97.out --root=./xonix97src/Ruby ./xonix97src/Ruby/xonix97.rb
# https://github.com/pmq20/ruby-packer/issues/39
```
