import { mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { Plugin } from 'vite';

const readmeOnGithub =
  'https://github.com/yefersonSegura/omega_architecture/blob/main/README.md';

/**
 * Copies Markdown from the repository `doc/` folder into `docs/doc/` so VitePress
 * can serve the same long-form Spanish reference as the rest of the site.
 * Rewrites relative README links so they work outside `doc/`.
 */
export function syncDocFromRepo(): Plugin {
  const here = dirname(fileURLToPath(import.meta.url));
  const repoDoc = join(here, '../../../doc');
  const destDir = join(here, '../../doc');

  function patchReadmeLinks(body: string): string {
    return body.replace(
      /\]\(\.\.\/README\.md(\#[^)]*)?\)/g,
      (_match, fragment: string | undefined) =>
        `](${readmeOnGithub}${fragment ?? ''})`,
    );
  }

  function sync(): void {
    mkdirSync(destDir, { recursive: true });
    let names: string[];
    try {
      names = readdirSync(repoDoc);
    } catch {
      return;
    }

    const frontmatter = `---
outline: deep
editLink: false
---

`;

    for (const name of names) {
      if (!name.endsWith('.md') || name === 'index.md') continue;
      const src = join(repoDoc, name);
      let raw: string;
      try {
        raw = readFileSync(src, 'utf8');
      } catch {
        continue;
      }
      writeFileSync(
        join(destDir, name),
        frontmatter + patchReadmeLinks(raw),
        'utf8',
      );
    }
  }

  return {
    name: 'sync-doc-from-repo',
    buildStart: sync,
    configureServer: sync,
  };
}
