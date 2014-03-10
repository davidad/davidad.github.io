---
layout: post
title: "How I Think About Math, <br/>Lecture 1: Relations"
date: 2014-03-10 11:05:40 -0400
comments: true
categories: 
---

Last week at [Hacker School](http://www.hackerschool.com), I floated the idea of
giving a presentation about linear algebra. Over a decade after taking it in
college, I finally feel like I understand linear algebra well enough to express
clearly, to an audience of programmers, most of the concepts from linear algebra
that they might find useful.

I figured the very first thing to present would be the concept of _linearity_
itself. After all, a **linear operator** is just any operator that commutes with
addition and scalar multiplication. But wait-- what is "commuting"? Well, no
problem, "_A_ and _B_ commute" just means that composing _A_ with _B_ yields the
same operator as composing _B_ with _A_. But wait-- what is "composing"? I
_could_ start my presentation by defining a category, but that would be
unnecessarily scary given category theory's fearsome reputation. Besides, John
Baez [showed me last
week](http://johncarlosbaez.wordpress.com/2014/03/02/network-theory-i/) that
categorical diagram notation has its boxes and arrows counterintuitively
swapped. But wait-- I could just use Baez's new notation, instead! Then my
entire discussion of linear algebra will be based on concrete, non-fearsome
**relations**, instead of "morphisms."

So...I got about as far as defining "commuting." (Linear algebra will have to
wait.)

[See the slides (PDF)](/assets/20140306.pdf). (You may want to use your PDF
viewer's presentation mode; there are a lot of pseudo-animations that could
get annoying to scroll through.)
* * *

Note: I'm skirting the edge of what Baez's formalism actually allows; in his
work so far, diagrams always depict morphisms, rather than logical assertions.
I'm still working on the semantics of quantifiers in this notation, so it's
conceivable some of the examples in these slides will change as I learn more.
