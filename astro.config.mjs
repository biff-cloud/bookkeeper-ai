import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
export default defineConfig({ site: 'https://biff-cloud.github.io', base: '/bookkeeper-ai', trailingSlash: 'ignore', integrations: [sitemap()] });
