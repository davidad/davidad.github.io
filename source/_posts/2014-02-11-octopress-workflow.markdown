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

    davidad@zayin ~/octopress> blog
    Enter a title for your post:

`blog` is a `bash` script, pretty specific to my own setup (vim, chrome, OSX),
but it could be adapted to other environments. `blog` can create a post using
Octopress' `new_post[]` Rake target (and you can specify a title on the command
line if you want), then it opens `vim` in sort of `git commit`-ish fashion, with
your cursor on the last line ready to press `o` and start typing your post, and
with magical deployment when you `:wq`[^1]. It also implements `blog deploy`
(runs both generate and deploy), `blog delete`, and editing existing posts. Most
importantly, whenever editing the script sets up a keybinding for `C-g` that
saves your draft post and refreshes the local preview in a Chrome window. It
does this even if you don't have a tab open to refresh, but it also won't open a
new one if you do. And it keeps your `vim` window in the foreground. How does
this work?  You might expect that Chrome has a nice command-line remote
interface for exactly this sort of thing. Sadly, that is not the case. However,
Apple has had the foresight to allow command-driven automation of actions which
can typically only be carried out graphically.  Sadly again, that mechanism is a
historical relic of a programming language, called AppleScript.

{% codeblock lang:applescript Reloading a website in AppleScript %}
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

In this snippet, `$1` is going to get replaced with the site's top-level URL
(like `http://localhost:4000/` for the local preview server, or
`http://davidad.github.io/` for the deployment). `$L1` and `$L2` are
placeholders for two actions that we might not always <nobr>want[^2]:</nobr>
changing the current tab to the tab we just refreshed, and opening up a new tab
if there wasn't already one for this site. It's also worth noting that this
script will reload the first tab that  _contains_ the URL -- so if you have an
open tab pointed at a particular page on the site, you won't lose your
place[^3].

The interface to AppleScript is the `osascript` command, which accepts an
AppleScript file as its argument[^4]. So, the first big chunk of the `blog`
script is dedicated to producing script files. It's implemented as a function
which fills in the "holes" in the script described above.

{% codeblock lang:bash start:8 %}
function wrs() {
    if [[ $2 = "y" ]]; then
        L1="set theWindow's active tab index to theTabIndex"
        L2="tell window 1 to make new tab with properties {URL:\"$1\"}"
    else
        L1=""
        L2=""
    fi
    cat >.reload.scpt <<EOF
delay 0.5
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
EOF
}
wrs 'http://localhost:4000/' y
{% endcodeblock %}

[^1]: Or `:x`. My muscle memory has been `:wq` for many years and I haven't yet made a serious effort to retrain.
[^2]: One example where we don't want these actions is if the blog post was aborted. Then there's no sense in tabbing back to the preview just to show that it's gone, but if the user is looking at the preview anyway, may as well refresh it to reflect the abort.
[^3]: Chrome will even restore your scroll position once the refresh is finished.
[^4]: You can also pass AppleScript in on `osascript`'s command line using the `-e` option, but only one line at a time. Since there's no statement separator in AppleScript, we can't easily transform an arbitrary script into a one-liner (like we could in `bash`, or many other more sensible languages).
