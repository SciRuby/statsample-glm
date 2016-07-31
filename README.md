# statsample-glm

[![Build Status](https://travis-ci.org/SciRuby/statsample-glm.svg?branch=master)](https://travis-ci.org/SciRuby/statsample-glm)

[![Gem Version](https://badge.fury.io/rb/statsample-glm.svg)](http://badge.fury.io/rb/statsample-glm)

Statsample-GLM is an extension of *Generalized Linear Models* to [Statsample](https://github.com/SciRuby/statsample), a suite of advance statistics in Ruby.

Requires ruby 2.0.0 or higher.

## Description

Statsample-glm includes the following Generalized Linear Models:

* Iteratively Reweighted Least Squares
  * Poisson Regression
  * Logistic Regression
* Maximum Likelihood Models (Newton Raphson)
  * Logistic Regression
  * Probit Regression
  * Normal Regression

Statsample-GLM was created by Ankur Goel as part of Google's Summer of Code 2013. It is the part of [the SciRuby Project](http://sciruby.com).

## Installation

  `gem install statsample-glm`


## Usage

To use the library 

  `require 'statsample-glm'`

### Blogs

* [Generalized Linear Models: Introduction and implementation in Ruby](http://v0dro.github.io/blog/2014/09/21/code-generalized-linear-models-introduction-and-implementation-in-ruby/).

### Case Studies

* [Logistic Regression Analysis with daru and statsample-glm](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Logistic%20Regression%20with%20daru%20and%20statsample-glm.ipynb)

## Documentation 

The API doc is [online](http://rubygems.org/gems/statsample-glm). For more code examples see also the spec files in the source tree.

## Project home page

  http://github.com/sciruby/statsample-glm

## Copyright

Copyright (c) 2013 Ankur Goel and the Ruby Science Foundation. See LICENSE.txt for further details.

Statsample is (c) 2009-2013 Claudio Bustos and the Ruby Science Foundation.
