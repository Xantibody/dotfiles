// Register home-manager's Firefox profiles in one selectable profile group.
//
// Usage: node main.mts <config dir> <store id> <manifest.json>
//
// The manifest is a list of {path, name, avatar}; the first entry is the
// fallback default. Firefox keeps the profile list in Profile Groups/<id>.sqlite
// and only one entry per group in profiles.ini, whose Path it rewrites when the
// user switches profiles, so profiles.ini must stay a writable file.

import { existsSync, lstatSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";

type Profile = { path: string; name: string; avatar: string };
type Ini = Map<string, Map<string, string>>;

// Same schema as Firefox's ProfilesDatastoreService. Firefox migrates
// user_version 1 to its current version the first time it opens the store.
const SCHEMA = `
CREATE TABLE IF NOT EXISTS Profiles (
  id INTEGER NOT NULL PRIMARY KEY, path TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL, avatar TEXT NOT NULL, themeId TEXT NOT NULL,
  themeFg TEXT NOT NULL, themeBg TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS SharedPrefs (
  id INTEGER NOT NULL PRIMARY KEY, name TEXT NOT NULL UNIQUE,
  value BLOB, isBoolean INTEGER);
`;

function readIni(path: string): Ini {
  const ini: Ini = new Map();
  // A symlink is home-manager's old read-only profiles.ini; treat it as absent.
  if (!existsSync(path) || lstatSync(path).isSymbolicLink()) return ini;
  let section: Map<string, string> | undefined;
  for (const line of readFileSync(path, "utf8").split("\n")) {
    const header = /^\[(.*)\]$/.exec(line);
    if (header) {
      section = new Map();
      ini.set(header[1]!, section);
      continue;
    }
    const eq = line.indexOf("=");
    if (section && eq > 0) section.set(line.slice(0, eq), line.slice(eq + 1));
  }
  return ini;
}

function writeIni(path: string, ini: Ini): void {
  const text = [...ini]
    .map(([name, kv]) => [`[${name}]`, ...[...kv].map(([k, v]) => `${k}=${v}`)].join("\n"))
    .join("\n\n");
  // Replace the inode so an old home-manager symlink is not followed.
  writeFileSync(`${path}.tmp`, `${text}\n`);
  renameSync(`${path}.tmp`, path);
}

function syncDb(root: string, storeId: string, profiles: Profile[]): void {
  mkdirSync(join(root, "Profile Groups"), { recursive: true });
  const db = new DatabaseSync(join(root, "Profile Groups", `${storeId}.sqlite`));
  db.exec(SCHEMA);
  // DO NOTHING keeps the colour and avatar picked in Firefox.
  const insert = db.prepare(
    `INSERT INTO Profiles (path, name, avatar, themeId, themeFg, themeBg)
     VALUES (?, ?, ?, 'default-theme@mozilla.org', 'rgb(21,20,26)', 'rgb(240,240,244)')
     ON CONFLICT(path) DO NOTHING`,
  );
  for (const p of profiles) insert.run(p.path, p.name, p.avatar);
  const row = db.prepare("PRAGMA user_version").get() as { user_version: number };
  if (row.user_version === 0) db.exec("PRAGMA user_version = 1");
  db.close();
}

function syncIni(root: string, storeId: string, profiles: Profile[]): void {
  const iniPath = join(root, "profiles.ini");
  const installsPath = join(root, "installs.ini");
  const ini = readIni(iniPath);
  const paths = profiles.map((p) => p.path);
  const inGroup = (p: string | undefined) => p !== undefined && paths.includes(p);

  const current = [...ini.values()].find((kv) => kv.get("StoreID") === storeId)?.get("Path");
  const installs = [...ini].filter(([name]) => name.startsWith("Install"));
  // Section names are hashes of the install directory. Dropping them makes
  // Firefox treat the install as new and create an empty profile for it.
  const hashes = [
    ...new Set([
      ...installs.map(([name]) => name.slice("Install".length)),
      ...readIni(installsPath).keys(),
    ]),
  ].sort();

  if (inGroup(current) && installs.every(([, kv]) => inGroup(kv.get("Default")))) return;
  const target = inGroup(current) ? current! : paths[0]!;

  const out: Ini = new Map([
    ["General", new Map([["StartWithLastProfile", "1"]])],
    [
      "Profile0",
      new Map([
        ["Name", profiles[0]!.name],
        ["IsRelative", "1"],
        ["Path", target],
        ["StoreID", storeId],
        ["Default", "1"],
      ]),
    ],
  ]);
  const outInstalls: Ini = new Map();
  for (const h of hashes) {
    const entry = new Map([
      ["Default", target],
      ["Locked", "1"],
    ]);
    out.set(`Install${h}`, entry);
    outInstalls.set(h, entry);
  }

  writeIni(iniPath, out);
  if (hashes.length > 0) writeIni(installsPath, outInstalls);
}

const [root, storeId, manifest] = process.argv.slice(2);
if (root === undefined || storeId === undefined || manifest === undefined) {
  console.error("usage: firefox-profile-group <config dir> <store id> <manifest.json>");
  process.exit(2);
}
const profiles = JSON.parse(readFileSync(manifest, "utf8")) as Profile[];
syncDb(root, storeId, profiles);
syncIni(root, storeId, profiles);
