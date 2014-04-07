---
layout: post
title: "Getting started with nginx configuration"
date: 2014-04-06 20:05:53 -0400
comments: true
categories: 
---

_Thanks to fellow [Hacker School](http://hackerschool.com)er Leah Steinberg for inspiring this post!_

* * *

Having intermittently struggled with `apache2` configuration files for nearly
half of my adult life, I find `nginx` an absolute joy to set up. I'm completely
sincere about that. But, for those who are just getting into Web development,
`nginx` is just about as much of a struggle as Apache used to be---in fact,
probably more so, because there's less abundant learning materials out there on
the Internet.

So, here's an attempt to make that situation just the slightest bit better.

If you don't already have `nginx` installed, I encourage you to follow [these
directions](http://openresty.org/#Installation) for building
[OpenResty](http://openresty.org/), an enhanced version of `nginx` that enables
building entire Web apps within the `nginx` process using the beautiful
programming language
[Lua](http://en.wikipedia.org/wiki/Lua_(programming_language)#Features).

But, from here on, I'm going to assume that you already have a stock version of
`nginx` installed. Verify that if you run

    $ nginx -v

you get some kind of reasonable response, like

    nginx version: nginx/1.2.3

Success!

Now, make a file called `hi.conf`:

```nginx hi.conf
error_log stderr;
pid nginx.pid;
http {
    access_log off;
    server {
        listen 4945;
        location / {
            return 200;
        }
    }
}
events {}
```

I've chosen the number 4945 so as to hopefully not conflict with any services
that may already be running on your machine for one reason or another. Now,
let's launch `nginx` using this configuration file and test it:

    $ nginx -p `pwd`/ -c hi.conf
    nginx: [alert] could not open error log file: open() "/var/log/nginx/error.log" failed (13: Permission denied)
    $ telnet localhost 4945
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.
    GET / HTTP/1.0

    HTTP/1.1 200 OK
    Server: nginx/1.2.3
    Date: Mon, 07 Apr 2014 01:50:28 GMT
    Content-Type: text/plain
    Content-Length: 0
    Connection: close

    Connection closed by foreign host.
    $ kill -QUIT `cat nginx.pid`

You'll have to actually enter the line `GET / HTTP/1.0`. HTTP is a protocol
intended for humans to be able to read and write, and you may as well take
advantage of it! Of course, you could also navigate to `http://localhost:4945/`
in a browser, but then all you see is a blank page, which is not quite as
satisfying (to me, at least) as a `200 OK` on the terminal[^1].

* * *

What's that? You want to actually serve data, and not just a blank page?

```nginx hi2.conf
error_log stderr;
pid nginx.pid;
http {
    access_log off;
    root .;
    server {
        listen 4945;
        location / {
            try_files /index.html =404;
        }
    }
}
events {}
```

Then just drop an `index.html` into the same folder as `hi2.conf` and run

    $ nginx -p `pwd`/ -c hi2.conf

Now you should be able to load `http://localhost:4945/` and see what you wrote
in `index.html`. Exciting!

## Next Steps

If you installed OpenResty, continue with their [Getting
Started](http://openresty.org/#GettingStarted). Otherwise, I'll leave you to
other tutorials, or to [the actual `nginx` documentation](http://nginx.org/en/docs/dirindex.html) --
this was really just an exercise in getting something to work. But, I will offer
this advice: I recommend against using any of your OS's magic, like special
files and folders where things are supposed to be put, or special incantations
for invoking `nginx`. Just run `nginx` on the command line.  It's a smart enough
program to **stay** running once you've started it, without the help of external
infrastructure, and I think you'll be much less frustrated working with it
directly, having all the relevant files in one project directory, than
struggling to configure both `nginx` itself and your OS's favorite mechanism for
managing server processes. Once you've figured out how to disable the OS's
auto-server-starting mechanisms, you can modify the `listen` line to `listen 80`
so you can stop typing that pesky `:4945` in the browser.

### Reloading

Oh, and one last trick: if you want to ask `nginx` to reload its configuration
file without actually bringing down the server, just

    $ kill -HUP `cat nginx.pid`

Happy hacking!

[^1]: 200 is the HTTP status code meaning "OK", the status that accompanies most
successful HTTP replies on the Web. As you might guess, that's the same 200
referred to by the line `return 200` in `hi.conf`.


