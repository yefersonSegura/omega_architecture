import { defineConfig } from 'vitepress';

export default defineConfig({
  title: 'Omega Architecture',
  description:
    'Reactive, agent-based architecture for Flutter — OmegaChannel, intents, flows, agents, CLI, and inspector.',
  lang: 'en-US',
  base: '/omega_architecture/',
  appearance: true,

  head: [
    ['link', { rel: 'icon', href: '/omega_architecture/omega-logo.svg', type: 'image/svg+xml' }],
    ['meta', { name: 'theme-color', content: '#00d2ff' }],
  ],
  themeConfig: {
    logo: '/omega-logo.svg',
    nav: [
      { text: 'Docs', link: '/guide/getting-started', activeMatch: '/guide/' },
      { text: 'Inspector (VM)', link: '/inspector.html', target: '_blank', rel: 'noopener noreferrer' },
      { text: 'About', link: '/guide/about' },
      { text: 'Repository', link: '/guide/repository' },
      { text: 'pub.dev', link: 'https://pub.dev/packages/omega_architecture' },
    ],

    sidebar: [
      {
        text: 'Get started',
        items: [
          { text: 'Getting started', link: '/guide/getting-started' },
          { text: 'Core concepts', link: '/guide/concepts' },
          { text: 'Data flow', link: '/guide/data-flow' },
          { text: 'omega_setup.dart', link: '/guide/omega-setup' },
          { text: 'Example app', link: '/guide/example-app' },
        ],
      },
      {
        text: 'Understand Omega',
        items: [
          { text: 'Vision & why Omega', link: '/guide/vision-and-why' },
          { text: 'About the author', link: '/guide/about' },
          { text: 'Total architecture', link: '/guide/total-architecture' },
          { text: 'Omega vs BLoC / Riverpod', link: '/guide/comparison' },
        ],
      },
      {
        text: 'Build features',
        items: [
          { text: 'Channel & events', link: '/guide/channel-events' },
          { text: 'Intents, flows & manager', link: '/guide/intents-flows-manager' },
          { text: 'Agents & behaviors', link: '/guide/agents-behaviors' },
          { text: 'Navigation & routes', link: '/guide/navigation-router' },
        ],
      },
      {
        text: 'Advanced',
        collapsed: true,
        items: [
          { text: 'Contracts (debug)', link: '/guide/contracts' },
          { text: 'Time travel & traces', link: '/guide/time-travel' },
          { text: 'Offline-first intents', link: '/guide/offline-first' },
        ],
      },
      {
        text: 'Tools & quality',
        items: [
          { text: 'Omega CLI', link: '/guide/cli' },
          { text: 'Inspector & VM Service', link: '/guide/inspector' },
          { text: 'Testing', link: '/guide/testing' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'API reference (pub.dev)', link: '/guide/api-reference' },
          { text: 'Repository layout', link: '/guide/repository' },
        ],
      },
    ],

    editLink: {
      pattern: 'https://github.com/yefersonSegura/omega_architecture/edit/main/docs/:path',
      text: 'Edit this page on GitHub',
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/yefersonSegura/omega_architecture' },
      {
        icon: {
          svg: '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/></svg>',
        },
        link: 'https://yefersonsegura.com/',
        ariaLabel: 'Yeferson Segura — portfolio',
      },
    ],

    footer: {
      message:
        'Omega Architecture (Flutter) — by <a href="https://yefersonsegura.com/" target="_blank" rel="noopener">Yeferson Segura</a>.',
      copyright: 'Copyright © present',
    },

    search: { provider: 'local' },
  },
});
