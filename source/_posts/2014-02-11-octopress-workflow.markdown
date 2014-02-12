---
layout: post
title: "Octopress workflow"
date: 2014-02-11 18:10:58 -0500
comments: true
categories: 
---

Today is my second day at [Hacker School](http://hackerschool.com), and I
decided to set up a little bit of tooling for blogging about what I do here.
The first tool I set up (following the recommendations of many Hacker Schoolers
and alums) was [Octopress](http://octopress.org), a static site generator
designed for [GitHub Pages](pages.github.com) and implemented atop
[Jekyll](http://jekyllrb.com). I followed the admirably thorough Octopress
documentation for [installation](http://octopress.org/docs/setup/),
[initial configuration](http://octopress.org/docs/configuring/),
[deployment with Github Pages](http://octopress.org/docs/deploying/github/), and
[theme customization](http://octopress.org/docs/theme/). But I wanted even more
convenience. So, I'm here to introduce you to the `blog` command.
{% codeblock lang:console linenos:false %}
davidad@zayin ~/octopress> blog
Enter a title for your post:
{% endcodeblock %}

It's pretty specific to my own setup (vim, chrome, OSX), but it could certainly
be adapted. It can create a post using Octopress' `new_post[]` Rake target (and
you can specify a title on the command line if you want), then it opens `vim` in
sort of `git commit`-ish fashion, with your cursor on the last line ready to
press `o` and start typing your post. Most importantly, the script sets up a
keybinding for `C-g` that saves your draft post and refreshes the local preview
in a Chrome window. It does this even if you don't have a tab open to refresh,
but it also won't open a new one if you do. And it keeps your `vim` window in
the foreground. How does this work? Sadly, a big pile of AppleScript.

{% codeblock lang:applescript %}
tell application "Google Chrome"

    if (count every window) = 0 then
        make new window
    end if

    set found to false
    set theTabIndex to -1
    repeat with theWindow in every window
        set theTabIndex to 0
        repeat with theTab in every tab of theWindow
            set theTabIndex to theTabIndex + 1
            if theTab's URL contains "$1" then
                set found to true
                exit
            end if
        end repeat

        if found then
            exit repeat
        end if
    end repeat

    if found then
        tell theTab to reload
        $L1
    else
        $L2
    end if
end tell
{% endcodeblock %}

