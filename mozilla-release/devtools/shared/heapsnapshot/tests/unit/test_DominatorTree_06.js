/* Any copyright is dedicated to the Public Domain.
   http://creativecommons.org/publicdomain/zero/1.0/ */
"use strict";

// Test that the retained size of a node is the sum of its children retained
// sizes plus its shallow size.

// Note that we don't assert directly, only if we get an unexpected
// value. There are just way too many nodes in the heap graph to assert for
// every one. This test would constantly time out and assertion messages would
// overflow the log size.
function fastAssert(cond, msg) {
  if (!cond) {
    ok(false, msg);
  }
}

let COUNT = { by: "count", count: false, bytes: true };

function run_test() {
  let path = saveNewHeapSnapshot();
  let snapshot = ChromeUtils.readHeapSnapshot(path);
  let dominatorTree = snapshot.computeDominatorTree();

  // Do a traversal of the dominator tree and assert the relationship between
  // retained size, shallow size, and children's retained sizes.

  let root = dominatorTree.root;
  let stack = [root];
  while (stack.length > 0) {
    let top = stack.pop();

    let children = dominatorTree.getImmediatelyDominated(top);

    let topRetainedSize = dominatorTree.getRetainedSize(top);
    let topShallowSize = snapshot.describeNode(COUNT, top).bytes;
    fastAssert(topShallowSize <= topRetainedSize,
               "The shallow size should be less than or equal to the " +
               "retained size");

    let sumOfChildrensRetainedSizes = 0;
    for (let i = 0; i < children.length; i++) {
      sumOfChildrensRetainedSizes += dominatorTree.getRetainedSize(children[i]);
      stack.push(children[i]);
    }

    fastAssert(sumOfChildrensRetainedSizes <= topRetainedSize,
               "The sum of the children's retained sizes should be less than " +
               "or equal to the retained size");
    fastAssert(sumOfChildrensRetainedSizes + topShallowSize === topRetainedSize,
               "The sum of the children's retained sizes plus the shallow " +
               "size should be equal to the retained size");
  }

  ok(true, "Successfully walked the tree");
  do_test_finished();
}