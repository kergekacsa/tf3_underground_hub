// Builds tram_end.tunnel.lua: the concrete car tunnel of the game, with the wall that closes a dead end.
// The tunnel script of the game closes a dead end only for a tunnel type that names five dead-end
// models. The rail tunnels do, the car tunnels name three, so an unconnected tram tunnel stays open
// and shows the empty space behind it. This copy names five. The two extra ones are for a dead end
// that covers only a part of the tunnel width, which the one street of a tram level never has.
// Run from the mod folder: node tools/build_tram_tunnel.js
// The tunnel is read from the game archive, so the game MUST be installed.
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const GAME_ARCHIVE = process.env.TF3_TUNNEL_ARCHIVE
  || 'C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 3/base/content/infrastructure/tunnel.zip';
const GAME_FILE = 'tunnel/tunnel_b_car.tunnel.lua';
const OUT_FILE = path.join(__dirname, '..', 'content', 'stations', 'rail', 'underground_hub', 'tram_end.tunnel.lua');

// Each entry replaces one text of the game file. A text that is missing stops the tool, so a change
// of the game file does not pass unseen.
const CHANGES = [
  // a path that starts with "/" names a game file only inside the game: a mod needs "::/"
  ['local newdir = "/infrastructure/tunnel/b_car/"', 'local newdir = "::/infrastructure/tunnel/b_car/"'],
  ['deadConfig = {tunnel_b_car_dead_rgt ,tunnel_b_car_dead_rep ,tunnel_b_car_dead_lft},',
    'deadConfig = { tunnel_b_car_dead_rgt, tunnel_b_car_dead_rep, tunnel_b_car_dead_lft, tunnel_b_car_dead_rgt, tunnel_b_car_dead_lft },'],
  // only the hub builds this tunnel: it is in no menu and has no year
  [/menuCategory = \{\s*categories = \{\s*\{\s*order = 30,\s*\},\s*\},\s*\},/, 'menuCategory = {\n\t\tcategories = {},\n\t},'],
  [/availability = \{\s*yearFrom = 1970,\s*\},/, 'availability = {\n\t\tyearFrom = -1,\n\t\tyearTo = -1,\n\t},'],
  ['fileName = "tunnel.script@tunnel.updateFn",', 'fileName = "::/infrastructure/tunnel/tunnel.script@tunnel.updateFn",'],
];

let text = execFileSync('unzip', ['-p', GAME_ARCHIVE, GAME_FILE], { maxBuffer: 1 << 26 }).toString('utf8').split('\r\n').join('\n');
for (const [from, to] of CHANGES) {
  const found = typeof from === 'string' ? text.includes(from) : from.test(text);
  if (!found) throw new Error('the game file has changed, not found: ' + from);
  text = text.replace(from, to);
}
const header = '-- Built by tools/build_tram_tunnel.js from the concrete car tunnel of the game. Do not edit.\n'
  + '-- The outer end of a tram level uses it: it closes the tunnel while no street is connected.\n';
fs.writeFileSync(OUT_FILE, header + text.replace(/^\n+/, ''));
console.log('tram tunnel written to ' + OUT_FILE);
