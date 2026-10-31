import * as fs from 'node:fs/promises'
import * as path from 'node:path'

const target = process.argv[2]
if (!target) {
  console.error('Usage: node resolve-linkts.mts <directory>')
  process.exit(1)
}

await resolveLinks(path.resolve(target))

async function resolveLinks(dir: string) {
  for (const entry of await fs.readdir(dir, { withFileTypes: true })) {
    const entryPath = path.join(dir, entry.name)

    // Scoped packages (@types, @tanstack, ...) are directories of symlinks
    if (entry.isDirectory() && entry.name.startsWith('@')) {
      await resolveLinks(entryPath)
      continue
    }

    if (!entry.isSymbolicLink()) continue

    const realPath = await fs.realpath(entryPath)
    const tmpPath = `${entryPath}.resolving`

    console.log(`${path.relative(process.cwd(), entryPath)} <- ${path.relative(process.cwd(), realPath)}`)

    // Copy alongside first so the link is only replaced once the copy succeeds
    await fs.rm(tmpPath, { recursive: true, force: true })
    await fs.cp(realPath, tmpPath, { recursive: true, verbatimSymlinks: true })
    await fs.unlink(entryPath)
    await fs.rename(tmpPath, entryPath)
  }
}
