---
layout: post
title: "VNC as a graphical interface medium"
date: 2014-03-30 19:21:34 -0400
comments: true
categories: 
---

The [Virtual Network Computing
(VNC)](http://en.wikipedia.org/wiki/Virtual_Network_Computing) system for
accessing the GUI environments of remote computers uses a protocol called
[Remote Frame Buffer (RFB)](http://en.wikipedia.org/wiki/RFB_protocol) to
exchange data about graphics output as well as keyboard and mouse input. RFB
turns out to be a very sane protocol (specification PDF
[here](http://www.realvnc.com/docs/rfbproto.pdf)) compared with X11, and
infinitely more sane than Cocoa (which requires the ObjC runtime) or Win32 (no
explanation needed). So, I thought, why not just expose a program's graphical
interface as a VNC server? Then we can let a VNC client deal with the vagaries
of the host windowing environment, and we only need to speak a well-specified
protocol on a socket.

So far, this is what I have to show ([code on
github](https://github.com/davidad/vnchacks)):  
![](/assets/color_rotate.gif)

<!-- more -->

This also turned out to be a good exercise in both raw socket programming and
the use of [`zlib`](http://www.zlib.net) (the
[DEFLATE](http://en.wikipedia.org/wiki/DEFLATE) compression library), both of
which I've skirted around before but never actually done directly in C[^1].
Check out my `open_port` function:

```c color_rotate_zrle.c https://github.com/davidad/vnchacks/blob/TJ-3/color_rotate_zrle.c#L14-23 link_text:context start:14
int open_port(uint16_t port) {
  int connfd, sockfd, y[1]={1};
  struct sockaddr_in addr = {.sin_family=AF_INET,.sin_port=htons(port),.sin_addr={.s_addr=htonl(INADDR_ANY)}};
  if( ( sockfd = socket(PF_INET, SOCK_STREAM, 0)                         ) < 0)  perror(  "socket"  );
  if( (      setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, y, sizeof(int))) < 0)  perror("setsockopt");
  if( (            bind(sockfd, (struct sockaddr*)&addr, sizeof(addr))   ) < 0)  perror(   "bind"   );
  if( (          listen(sockfd, 1)                                       ) < 0)  perror(  "listen"  );
  if( ( connfd = accept(sockfd, NULL, 0)                                 ) < 0)  perror(  "accept"  );
  return connfd;
}
```

Once the socket connection is established, there's some handshaking to do (as
you can see, this is pretty stubby --- it doesn't wait for any messages from the
client):

```c color_rotate_zrle.c https://github.com/davidad/vnchacks/blob/TJ-3/color_rotate_zrle.c#L53-59 link_text:context start:53
  int   connfd = open_port(PORT);
  write(connfd, protover,          sizeof(protover)-1);
  write(connfd, securitytype,      sizeof(securitytype));
  write(connfd, securitychallenge, sizeof(securitychallenge));
  write(connfd, securityresult,    sizeof(securityresult));
  write(connfd, serverInit,        sizeof(serverInit));
  write(connfd, name,              sizeof(name)-1);
```

Then, we can get down to business:

```c color_rotate_zrle.c https://github.com/davidad/vnchacks/blob/TJ-3/color_rotate_zrle.c#L61-85 link_text:context start:61
  z_streamp z = malloc(sizeof(z_stream));
  deflateInit(z,6);
  uint8_t* buf=malloc(FBUFZ);
  uint8_t tile[] = {0x01, 0, 0, 255}; //solid blue
  const int frame_size=sizeof(tile)*(width/64)*(height/64);
  uint8_t* frame=malloc(frame_size);
  int t;
  double h=0, c=1, l=0.5;
  while(1) {
    hcl2pix(&tile[1],h,c,l);
    h+=0.01;
    for(t=0;t<(width/64)*(height/64);t++)
      memcpy(&frame[t*sizeof(tile)],tile,sizeof(tile));
    z->next_in=frame;
    z->avail_in=frame_size;
    z->next_out=buf;
    z->avail_out=FBUFZ;
    z->total_out=0;
    deflate(z,Z_SYNC_FLUSH);
    int length = htonl(z->total_out);
    write(connfd,fbuf_refresh,sizeof(fbuf_refresh));
    write(connfd,&length,4);
    write(connfd,buf,z->total_out);
    usleep(1e6/30);
  }
```

I've chosen to implement the encoding scheme ZRLE here, but most VNC clients
will also support streaming raw pixel data, which would remove the dependency on
`zlib` and simplify the logic somewhat[^2]. In the ZRLE encoding, the display
area is split into 64x64-pixel "tiles", each of which can be described in a
variety of palletized and non-paletized encodings. The simplest --- the one
we're using here --- is the one-color palette, introduced by `0x01`, and
containing simply the one color (no further data is needed, since it's implied
that every pixel in the tile is that color). So, in our main display loop, we
first update the tile (the `hcl2pix` function is one of my own devising, which
you can find in
[`colorspaces.c`](https://github.com/davidad/vnchacks/blob/master/colorspaces.c)),
then copy the (64x64) tile as many times as necessary to make a complete frame,
then `deflate` it, and finally write it out to the socket and wait until it's
time for the next frame. That's the essence of the program right there.

You may also be interested in the details of the RFB message formats:

```c color_rotate_zrle.c https://github.com/davidad/vnchacks/blob/TJ-3/color_rotate_zrle.c#L25-51 link_text:context start:25
const char protover[] = "RFB 003.003\n";
const char securitytype[] = {0x00, 0x00, 0x00, 0x02};
const char securitychallenge[16] = {0xaa};
const char securityresult[4] = {0};
const char name[] = "hello!";
const uint16_t width=1024, height=1024;

int main() {
  const char serverInit[] = {
    /*frame size*/   width>>8, width&0xff, height>>8, height&0xff,
    /*bpp*/ 32, /*depth*/ 24, /*big-endian*/ 0, /*true-colour*/ 1,
    /*red mask*/     0, 0xff,
    /*green mask*/   0, 0xff,
    /*blue mask*/    0, 0xff,
    /*red shift*/    0,
    /*green shift*/  8,
    /*blue shift*/  16, /*padding*/ 0,0,0,
    /*name length*/  0, 0, 0, sizeof(name)-1 };
  const char fbuf_refresh[] = {
    /*message-type*/ 0,
    /*padding*/      0,
    /*nrects*/       0, 1,
    /*xpos*/         0, 0,
    /*ypos*/         0, 0,
    /*width*/        width>>8, width&0xff,
    /*height*/       height>>8, height&0xff,
    /*encoding-type*/0, 0, 0, 16 };
```

Future work includes:

* Splitting out the frame encoding process to a `send_rect` function
* Actually parsing messages from the VNC client
* Providing user input handlers
* Comparing to an [SDL](http://www.libsdl.org) backend: same `send_rect` and `register_handler` abstractions might be nearly as easy to implement
* Implementing a box model to route user input to interface elements
* Implementing font rendering with [FreeType](http://www.freetype.org/)
* Implementing [TeX](http://www.ctex.org/documents/shredder/src/texbook.pdf)+[TikZ](http://ftp.math.purdue.edu/mirrors/ctan.org/graphics/pgf/base/doc/generic/pgf/pgfmanual.pdf) style graphics (big job)
* Creating useful interface elements for this platform

[^1]: Yes, I did this in C. Almost every operation in the program is a function
call, following the C calling convention, so it really wouldn't be fun to do in
assembly.
[^2]: Why did I choose ZRLE, then? Well, partly because I thought it was cool,
and partly because I wanted to get some practice using `zlib`. But mostly
because Apple's "Screen Sharing" VNC client advertises ZRLE as one of few standard RFB
encodings it accepts. Yet, this code as it is still doesn't work with Screen
Sharing. I wound up testing it with
[Chicken](http://sourceforge.net/projects/chicken/) instead.
