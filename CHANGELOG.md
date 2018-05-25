# CHANGELOG

## v1.0.0

### 1. Overview

The package is much smaller now and just provides support for the
other packages in the `Harnais` family.

### 2. Standard Function API Style

The package family has adopted a standard API style that returns either `{:ok, any}` or `{:error, error}` where `error` is an `Exception`.  

Peer bang functions raise the `error` or return the `value`.

### 2. Breaking Internal Changes

These changes do not affect the public APIs.

#### Renamed Harnais.Attributes as Harnais.Attribute

Consistent use of singular module names.

#### Deleted Harnais.Runner Modules, etc

`Harnais.Runner` related modules, attributes, etc have been deleted
from this package and are migrating into its own package.

#### Deleted Other Modules

Other utility modules have been deleted.

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

#### Added

1.  Harnais.runner\_test\_normalise\_canon\_keys/1
2.  Harnais.runner\_test\_normalise\_canon\_keys!/1
3.  Harnais.runner\_test\_maybe\_normalise\_canon\_keys/1
4.  Harnais.runner\_spec\_normalise\_canon\_keys/1
5.  Harnais.runner\_spec\_normalise\_canon\_keys!/1
6.  Harnais.runner\_spec\_maybe\_normalise\_canon\_keys/1

These functions can be used in e.g. a *test\_mapper* or helper
function to normalise the keys in the *runner specification*  or a
*test\_specification*.

#### Begun adding standard test suites in \`Harnais.Runner.Tests\`

The suites can be used to test e.g. delegations. So far suites for
**Map** and **Stream** / **Enum**.

Each test is a suite is \`Map\` form where the keys are the
**shortest** alias (e.g. *:v* not *:test\_value*).  Test mappers can
be applied in the usual way.

## v0.1.0 - 1st Release

