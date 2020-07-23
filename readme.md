# Xonix97

Based on the Xonix32 made originally for Windows95. All inspired by the original DOS Xonix.

The main difference between Xonix32 and original Xonix is moving orange-yellow lines that pain back the field.

## Why

To learn:
1. Gaming frameworks for Ruby
1. Concepts behind creating games
1. Flood Fill algorithm
1. Bresenham's Line algorithm
1. Generate binaries from Ruby
1. Make Mac/OS X app from Ruby binary

Despite visual simplisity this game provides opportunity to learn and experiment with couple of pretty cool algorithms.

## The real story

I actally attempted to do it when I was 18-20 yo and I thought it's way too hard and my solution is terrible. Looking back I was actually pretty good despite making some not very efficient decisions.

This time I decided to spend more time on revers-engineering the game instead of just comming up with my own solutions first. I knew that source code of an older Xonix32 version is avilable, had to dig a little in the Internet. Also had to find and install Windows98 and Visual C++ 6.0 in a virtual machine.

Ability to play around with the code helped a lot to understand the approach as well as reproduce the game more closely.

## What's up with the folder structure?

Ruby code goes into binary and binary goes into Mac/OS X App. Currently using rubyc for binary creating and Platypus for the app. That folder structure makes it easier to manipuate all these transformations.

