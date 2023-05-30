/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */

// @ts-check

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  "docs": [
    "index",
    {
      "type": "category",
      "collapsible": true,
      "collapsed": false,
      "label": "Quickstarts",
      "items": [
        {
          type: 'autogenerated',
          dirName: 'quickstart',
        }
      ]
    },
    {
      "type": "category",
      "collapsible": true,
      "collapsed": false,
      "label": "Miscellaneous",
      "items": [
        {
          type: 'autogenerated',
          dirName: 'misc',
        }
      ]
    },
    {
      "type": "category",
      "collapsible": true,
      "collapsed": false,
      "label": "Developer How-To",
      "items": [
        {
          type: 'autogenerated',
          dirName: 'dev_howto',
        }
      ]
    },
    {
      "type": "category",
      "collapsible": true,
      "collapsed": false,
      "label": "Documentation",
      "items": [
        {
          type: 'autogenerated',
          dirName: 'documentation',
        }
      ]
    },
  ],
  // But you can create a sidebar manually
  /*
  tutorialSidebar: [
    'intro',
    'hello',
    {
      type: 'category',
      label: 'Tutorial',
      items: ['tutorial-basics/create-a-document'],
    },
  ],
   */
};

module.exports = sidebars;