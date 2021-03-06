// Copyright (c) 2012 Ecma International.  All rights reserved.
// This code is governed by the BSD license found in the LICENSE file.

/*---
esid: sec-date.now
es5id: 15.9.4.4-0-3
description: Date.now must exist as a function
---*/

var fun = Date.now;

assert.sameValue(typeof(fun), "function", 'typeof (fun)');

reportCompare(0, 0);
