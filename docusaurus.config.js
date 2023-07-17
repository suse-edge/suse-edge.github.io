// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'SUSE Edge Team',
  tagline: 'Engineering your next Edge Infrastructure',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://suse-edge.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub Pages adds a trailing slash to Docusaurus URLs by default.
  trailingSlash: false,

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'suse-edge', // Usually your GitHub org/user name.
  projectName: 'suse-edge.github.io', // Usually your repo name.
  deploymentBranch: 'gh-pages', 

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internalization, you can use this field to set useful
  // metadata like html lang. For example, if your site is Chinese, you may want
  // to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          routeBasePath: '/docs', // Serve the docs at the site's root
          sidebarPath: require.resolve('./sidebars.js'),
          include: ['**/*.md', '**/*.mdx'],
          showLastUpdateAuthor: true,
          showLastUpdateTime: true,
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/suse-edge/suse-edge.github.io/tree/main/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
        blog: {
          showReadingTime: true,
          routeBasePath: '/blog'
        },
      }),
    ],
  ],

  plugins: [
    [require.resolve('docusaurus-lunr-search'),
        {
            indexBaseUrl: true
        }
    ]
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Replace with your project's social card
      image: 'img/suse-edge-social-card.jpg',
      navbar: {
        title: 'SUSE Edge site',
        logo: {
          alt: 'SUSE Edge Logo',
          src: 'img/edge-logo.svg',
        },
        items: [
          {
            type: 'doc',
            docId: 'index',
            position: 'left',
            label: 'Documentation',
          },
          {
            to: 'blog',
            label: 'Blog',
            position: 'left'
          },
          {
            href: 'https://github.com/suse-edge/',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'SUSE Edge',
                to: '/',
              },
            ],
          },
          {
            title: 'Community',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/suse-edge',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} SUSE Edge team. All Rights Reserved. Built with Docusaurus.`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
      },
    }),
};

module.exports = config;
