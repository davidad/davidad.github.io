---
layout: post
title: "All Boolean functions are polynomials"
date: 2014-04-14 10:47:37 -0400
comments: true
categories: 
---
...in the integers mod 2 (a.k.a. the finite field of order 2).  Multiplication
mod 2 is `AND`:

| A | B | (AB) |A B `AND`|
|:-:|:-:|:-----:|:-------:|
| 0 | 0 |   0   |    0    |
| 0 | 1 |   0   |    0    |
| 1 | 0 |   0   |    0    |
| 1 | 1 |   1   |    1    |

<br>
Adding one mod 2 is `NOT`:

| A | (A+1) | A `NOT` |
|:-:|:-----:|:-------:|
| 0 |   1   |    1    |
| 1 |   0   |    0    |

<br>
So, multiplication plus one is `NAND`:

| A | B | (AB+1) |A B `NAND`|
|:-:|:-:|:---------:|:-------:|
| 0 | 0 |   1   |    1    |
| 0 | 1 |   1   |    1    |
| 1 | 0 |   1   |    1    |
| 1 | 1 |   0   |    0    |

<br>
Since `NAND` is universal, and any finite composition of polynomials is
a polynomial, any finite boolean circuit is a polynomial. Here's all 16 two-input
functions:
<!-- more -->

| Lookup table | Boolean function ([RPN](http://en.wikipedia.org/wiki/Reverse_Polish_notation)) | Polynomial | Polynomial bitmap |
|:------------:|:----------------:|-----------:|:----:|
|     0000     |        0         |           0| 0000 |
|     0001     |    A B `AND`     |          AB| 0001 |
|     0010     | A (B `NOT`) `AND`  |        AB+A| 0101 |
|     0011     |        A         |           A| 0100 |
|     0100     | (A `NOT`) B `AND`  |        AB+B| 0011 |
|     0101     |        B         |           B| 0010 |
|     0110     |    A B `XOR`     |         A+B| 0110 |
|     0111     |    A B `OR`      |      AB+A+B| 0111 |
|     1000     |   A B `OR` `NOT` |    AB+A+B+1| 1111 |
|     1001     |  A B `XOR` `NOT` |       A+B+1| 1110 |
|     1010     |     B `NOT`      |         B+1| 1010 |
|     1011     |  A (B `NOT`) `OR`  |      AB+B+1| 1011 |
|     1100     |     A `NOT`      |         A+1| 1100 |
|     1101     |  (A `NOT`) B `OR`  |      AB+A+1| 1101 |
|     1110     |  A B `AND` `NOT` |        AB+1| 1001 |
|     1111     |        1         |           1| 1000 |

<br>
It's interesting that in many cases, including those corresponding to the
"basic" functions of `AND`, `OR`, `XOR` and `NOT`, the polynomial bitmap is
identical to the lookup table.

It's also interesting that these polynomials are either multilinear (linear in
each variable) or the sum of a multilinear polynomial with 1.

Naturally, I'm not the first person to notice this. It was first noticed [by I.
I. Zhegalkin in 1927](http://en.wikipedia.org/wiki/Zhegalkin_polynomial). And I
haven't yet found any especially compelling uses of the representation. (If you
actually want to represent boolean functions, you're probably better served by
[ZDDs](http://crypto.stanford.edu/pbc/notes/zdd/).) But I found it an
interesting discovery which might just come in handy someday.


