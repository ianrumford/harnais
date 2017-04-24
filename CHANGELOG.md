# CHANGELOG

## v0.1.0 - 1st Release

## v0.2.0

### 1. Enhancements

#### More consistent naming of functions.

#### Improvements to transforming a *test\_specification*

A new option *test\_transform* has been added to define the
**complete** transform pipeline applied to a *test\_specification*.
The *test\_transform* can be one or more arity 1 or 2 functions.

If no *test\_transform* is provided, the
*test\_mapper* functions (if any) and the internal normalisation function(s) are
used to define the transform pipeline.

The transform pipeline is composed into a single transform function that is applied to all
tests.

Any function that returns a *nil* short circuits the 
pipeline and causes the test to be discarded.  

#### Separated the normalisation of the runner specification from a test specification.

In v0.1.0 the allowed aliases included (conflated) both the runner specification and test specification.
These are now separated so that a test specification key (e.g. *:c*) may not
appear in the runner specification.  Note some keys appear in both
(e.g. *:test\_value*)

#### Added to Harnais and Harnais.Runner

1.  run\_test\_canon\_keys/1
2.  run\_test\_canon\_keys!/1
3.  run\_test\_maybe\_canon\_keys/1
4.  run\_spec\_canon\_keys/1
5.  run\_spec\_canon\_keys!/1
6.  run\_spec\_maybe\_canon\_keys/1

These functions can be used in e.g. a *test\_mapper* or helper
function to normalise the keys in the *run specification*  or a
*test specification*.

#### Standard test suites in Harnais.Runner.Tests

The suites are intended to be used as the basis for further
customisation (using mappers). So far only a suite for
**Map** is available.

Each test in a suite is \`Map\` form where the keys are the
**shortest** alias (e.g. *:v* not *:test\_value*).  Test transforms
/ mappers can be applied in the usual way.
