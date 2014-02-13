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
[Jekyll](http://jekyllrb.com). (The page you're reading right now is
Octopress-generated.) I followed the admirably thorough Octopress documentation
for [installation](http://octopress.org/docs/setup/), [initial
configuration](http://octopress.org/docs/configuring/), [deployment with Github
Pages](http://octopress.org/docs/deploying/github/), and [theme
customization](http://octopress.org/docs/theme/)[^1]. But I wanted even more
convenience. So, I'm here to introduce you to the `blog` command (the same one
I used to write this very post).

    davidad@zayin ~/octopress> blog
    Enter a title for your post:

`blog` is a `bash` script, pretty specific to my own setup (vim, chrome, OSX),
but it could be adapted to other environments. `blog` can create a post using
Octopress' `new_post[]` Rake target (and you can specify a title on the command
line if you want), then it opens `vim` in sort of `git commit`-ish fashion, with
your cursor on the last line ready to press `o` and start typing your post, and
with magical deployment when you `:wq`[^2]. It also implements `blog deploy`
(runs both generate and deploy), `blog delete`, and editing existing posts. Most
importantly, whenever editing the script sets up a keybinding for `C-g` that
saves your draft post and refreshes the local preview in a Chrome window. It
does this even if you don't have a tab open to refresh, but it also won't open a
new one if you do. And it keeps your `vim` window in the foreground. How does
this work?  You might expect that Chrome has a nice command-line remote
interface for exactly this sort of thing. Sadly, that is not the case. However,
Apple has had the foresight to allow command-driven automation of actions which
can typically only be carried out graphically.  Sadly again, that mechanism is
[**AppleScript**](http://en.wikipedia.org/wiki/AppleScript), a historical relic
of a programming language.

```applescript Reloading a website in Chrome from AppleScript
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
```

In this snippet, `$1` is going to get replaced with the site's top-level URL
(like `http://localhost:4000/` for the local preview server, or
`http://davidad.github.io/` for the deployment). `$L1` and `$L2` are
placeholders for two actions that we might not always <nobr>want[^3]:</nobr>
changing the current tab to the tab we just refreshed, and opening up a new tab
if there wasn't already one for this site. It's also worth noting that this
script will reload the first tab that  _contains_ the URL -- so if you have an
open tab pointed at a particular page on the site, you won't lose your
place[^4].

The interface to AppleScript is the `osascript` command, which accepts an
AppleScript file as its argument[^5]. So, the first big chunk of the `blog`
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
delay 0.9
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

The `delay 0.9` line exists to give Octopress enough time to do its thing before
trying to reload Chrome. Octopress is pretty slow.

In the next chunk, we handle the `delete` and `deploy` actions:

{% codeblock lang:bash start:3 %}
ORIGDIR=`pwd | sed 's/\ /\\ /g'`
cd ~/octopress

URL="http://davidad.github.io/"
{% endcodeblock %}

{% codeblock lang:bash start:53 %}
if [[ $1 = delete ]]; then
    [[ -f $2 ]] && rm -i $2 && bundle exec rake generate && exec $0 deploy
    exit 0
elif [[ $1 = deploy ]]; then
    bundle exec rake deploy \
    && wrs $URL y && sleep 3 && osascript ./.reload.scpt \
    && rm -f ./.reload.scpt .timeref rake_preview.log \
    && git add . \
    && git commit -m "Site updated at `date -u +"%Y-%m-%d %H:%M:%S UTC"`" \
    && git push
    exit 0
fi
{% endcodeblock %}

In the case of `delete`, we use `rm -i` to ask the user to confirm the deletion,
and if they do, we generate and then call the script itself (`$0`) with the
deploy action (so as not to duplicate code). The deploy action deploys the
generated site (to GitHub Pages), writes out a refresh script for the deployed
site, waits an extra few seconds for GitHub Pages to do its thing, and then runs
the reload script. Finally,`blog` commits and pushes the `source` branch of the
repository, after cleaning up its temporary files -- the reload script, the log
from Octopress' local preview server, and the time reference (which we'll come
to shortly).

{% codeblock lang:bash start:66 %}
[[ -f $1 ]] && rm -f new_post.md && ln -s $1 new_post.md
[[ -f $1 ]] || bundle exec rake "new_post[$1]"
{% endcodeblock %}

We're managing a symbolic link called `new_post.md` here, which is what we're
going to call `vim` on. If a filename is specified, we point the link directly
at that file. Otherwise, we're going to call `rake` to set up the file. By
default, `rake` won't give any indication to our script of what file it made, so
we're going to make a tweak to the `Rakefile`:

{% codeblock lang:diff %}
@@ -104,9 +89,7 @@ task :new_post, :title do |t, args|
   raise "### You haven't set anything up yet. First run `rake install` to set up an Octopress theme." unless File.directory?(source_dir)
   mkdir_p "#{source_dir}/#{posts_dir}"
   filename = "#{source_dir}/#{posts_dir}/#{Time.now.strftime('%Y-%m-%d')}-#{title.to_url}.#{new_post_ext}"
-  if File.exist?(filename)
-    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
-  end
+  if not (File.exist?(filename) and ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n')
     puts "Creating new post: #{filename}"
     open(filename, 'w') do |post|
       post.puts "---"
       post.puts "layout: post"
       post.puts "title: \"#{title.gsub(/&/,'&amp;')}\""
       post.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %z')}"
       post.puts "comments: true"
       post.puts "categories: "
       post.puts "---"
     end
+  end
+  system "rm -f new_post.md"
+  system "ln -s #{filename} new_post.md"
 end
{% endcodeblock %}

The first changeset handles the case where I don't want to overwrite the
existing post, but I _do_ want to proceed to edit it (and deploy the edits).
The last two lines simply point `new_post.md` at the right spot so our script
can call `vim` on it.  Before we call vim, though, we have to set up the
deploy-on-save feature and the live(ish)-preview feature...

{% codeblock lang:bash start:69 %}
touch -m .timeref
{% endcodeblock %}

`.timeref` is an empty file which keeps track of the time slightly before vim
was launched. In a "successful" session, the modification time of the post file
should be newer than `.timeref`, whereas if you `:q!` immediately, it won't be.
Now, it's worth pointing out that the live-preview requires saving along the
way, so **if you want to abort after previewing, use `:cq`**, `vim`'s command
for exiting with a nonzero status code (so the shell script knows what's up).
The script supports both mechanisms, so that if you are aborting immediately
but forget to `:cq`, The Right Thing should happen.

{% codeblock lang:bash manage preview processes start:70 %}
ps x | egrep 'rake|rackup|jekyll|sass|compass' | grep -v grep | awk '{ print $1 }' | xargs kill
ps x | egrep 'rackup' | grep -v grep | awk '{ print $1 }' | xargs kill -9
bundle exec rake preview > rake_preview.log 2>&1 &
{% endcodeblock %}

Now we're going to kill off any existing preview processes (they really start
to pile up otherwise!) and launch a new one. We also log its `stdout` and
`stderr` so you can see what the preview process is up to if you want (`tail -f
rake_preview.log`).

{% codeblock lang:bash start:73 %}
sleep 0.3
osascript ./.reload.scpt
{% endcodeblock %}

We give the preview process a little time to get started and then display the
preview in the browser so the user knows what they're working from.

{% codeblock lang:bash Run vim start:76 %}
vim -c 'set tw=80' -c 'map <C-G> :w<CR>:!osascript ./.reload.scpt<CR><CR>' \
    -c "cd $ORIGDIR" + new_post.md 
VIM_STATUS=$?
[[ `readlink new_post.md` -nt .timeref ]] || VIM_STATUS=1
[ $VIM_STATUS -eq 0 ] && osascript ./.reload.scpt && exec $0 deploy && exit 0
[ $VIM_STATUS -ne 0 ] && wrs 'http://localhost:4000/' n \
    && [ -f new_post.md ] && rm -i `readlink new_post.md` \
    && git rm --ignore-unmatch new_post.md \
    && sleep 0.4 && osascript ./.reload.scpt
{% endcodeblock %}

This is the last piece of the script, where we actually run `vim` and then take
the appropriate action after it exits. We're giving `vim` a number of commands
on the command line, including setting auto-wrapping at 80 columns (`tw=80`),
scrolling to the bottom of the file (`+`), and changing to the directory the
script was run from (set all the way back on line 3). Most importantly, we're
forcing a normal-mode mapping of `C-g` to the reload script!

Once `vim` exits, we capture its return code with `$?`. Then we check if the
file has actually been saved. Either it has, _or_ (`||`) the status really ought
to be nonzero. If the status is still `0`, then we do one final preview and
shift into deploy mode. Otherwise, we remove the file that `new_post.md` points to, remove `new_post.md` itself, and reload[^6].

### Phew!

Future blog posts will probably be somewhat less detailed, unless someone really likes
all this info.

[^1]: All of the files for theming etc. are available [here](https://github.com/davidad/davidad.github.io/tree/source). I've spent way too much time tweaking the CSS, and fixing various peeves with the way Octopress renders -- I could write an entire other blog post about that, but I probably won't.
[^2]: Or `:x`. My muscle memory has been `:wq` for many years and I haven't yet made a serious effort to retrain.
[^3]: One example where we don't want these actions is if the blog post was aborted. Then there's no sense in tabbing back to the preview just to show that it's gone, but if the user is looking at the preview anyway, may as well refresh it to reflect the abort.
[^4]: Chrome will even restore your scroll position once the refresh is finished.
[^5]: You can also pass AppleScript on `osascript`'s command line using the `-e` option, but only one line of AppleScript at a time. And since there's no statement separator in AppleScript, we can't easily transform an arbitrary script into a one-liner (like we could in `bash`, or many other more sensible languages).
[^6]: using a newly generated AppleScript which won't cause Chrome to switch the active tab, in case the abort was related to something else having come up.
