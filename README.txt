= git-lighthouse

* http://github.com/schacon/git-lighthouse

== DESCRIPTION:

Provides command line access to a Lighthouse ticketing system
for a git based software package.  Allows you to list, view and 
apply new patches that were submitted to Lighthouse.

== SYNOPSIS:

First, setup your Lighthouse data in your git repo:

git config lighthouse.account rails
git config lighthouse.projectId 8994
git config lighthouse.email name@email.com
git config lighthouse.password asdqwe

You can also setup an alias, if you prefer 'git lh' to 'git-lh':

git config --global alias.lh '!git-lh'

Then, you can list open tickets with patches:

$ git-lh list

Date	Num	Attch	Title
05/01	87	1	Dependencies shouldn't swallow errors from required files.
05/02	94	2	quote_string don't work with some postgres drivers
05/08	142	1	belongs_to association not updated when assigning to foreign key
05/14	191	0	Belongs to polymorphic association assignment with new records doesn't
05/14	192	1	AR Test failure on latest mysql 

You can show one of the tickets:

$ git-lh show 94

Title   : quote_string don't work with some postgres drivers
Number  : 94

URL     : http://rails.lighthouseapp.com/projects/8994/tickets/94
Created : Fri May 02 08:24:20 UTC 2008
State   : open
Tags    : activerecord patch

-- Attachments --

  1 : quote_string_fix.diff
  2 : postgres.so


You can get an attachment:

$ git-lh attachment 94 1 > quote_string_fix.diff

You can checkout an attachment - this will automatically stash whatever you're
working on, checkout a new branch called 'ticket94' and run either 'git am' or
'git apply', depending on what kind of patch file it is.

$ git-lh checkout 94 1

This will also checkout the commit closest to the date that the patch was uploaded,
which helps them apply cleanly.

== REQUIREMENTS:

* Ruby/Git >= 1.0.7 (gem install git)

== INSTALL:

* sudo gem install schacon-ruby-git --source=http://gems.github.com
* sudo gem install schacon-git-lighthouse --source=http://gems.github.com

== TODO:

Eventually, I will try to add this functionality, too:

* add comments to a ticket, including '+1's
* create a new ticket
* upload a new version of a patch, a set of patches, or an extra patch
* apply several/all patches from a ticket

== AUTHORS:

* Scott Chacon (schacon@gmail.com)

== LICENSE:

(The MIT License)

Copyright (c) 2008 Scott Chacon

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.