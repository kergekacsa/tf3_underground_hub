// Builds the models of the stairs between neighbouring levels, in models/:
//   hall_doors.mdl       the hall of the game without the four corridor walls that face the stairs from the ring,
//                        and with ceiling lights that are always on
//   hall_door_plugs.mdl  those four walls, for a level without stairs down
//   surface.mdl          the entrance building of the game, with ceiling lights that are always on
//   level_stairs.mdl     the stairs from the four openings down to a shared platform inside the ring of the next level
//   exit_stairs.mdl      the two stairs from the shared platform down to the ring
//   platform_rail.mdl    one piece of the railing around the shared platform
//   back_hedge.mdl       a hedge of the game that does not reach down into the entrance stairs
//   mat/, mat/tex/       copies of four materials of the game, with DXT1 copies of five of their textures
// Run in kacsa_underground_hub_dev: node tools/build_stair_models.js
// The hall is read from the game archive, so the game MUST be installed. All lengths are in metres,
// in the coordinates of the upper level.
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const GAME_ARCHIVE = process.env.TF3_STREET_ARCHIVE
  || 'C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 3/base/content/stations/street.zip';
const GAME_MODEL_DIR = 'street/underground_station/models/';
const GAME_MODEL_PATH = '::/stations/street/underground_station/models/';
const HEDGE_ARCHIVE = process.env.TF3_BUILDINGS_ARCHIVE
  || path.join(path.dirname(path.dirname(GAME_ARCHIVE)), 'assets', 'buildings', 'res.zip');
const HEDGE_DIR = 'res/hedges/';
const HEDGE_PATH = '::/assets/buildings/res/hedges/';
const HEDGE_MODEL = 'hdg_02_3m.mdl';
const HEDGE_MESH = 'msh/hdg_02_3m_lod2.002_lod';
const HEDGE_MIN_Z = -1.0;       // the ceiling of the entrance stairs lies 1.69 m deep below the back hedge
const CONTENT_DIR = path.dirname(path.dirname(GAME_ARCHIVE));
const OUT_DIR = path.join(__dirname, '..', '..', 'kacsa_underground_hub', 'content', 'stations', 'rail', 'underground_hub', 'models');

// ---------- geometry of the hall of the game, measured in its mesh
const DOOR_X = 13.0;            // plane of the corridor wall beside the foot of the stairs from the ring
const HALL_WALL_Y = 7.0;        // side wall of the hall
const STAIR_ZONE_Y = 10.24;     // edge between the walkway to the platform and the stairs from the ring
const CORRIDOR_Z = -17.65;      // floor of the corridor and of the platforms
const ROOM_HEIGHT = 3.5;        // corridor floor to corridor ceiling
const LEVEL_SPACING = 18.0;
const RING_Z = -12.0;
const RING_INNER_RADIUS = 7.0;  // the gallery of the ring starts here; inside it the hall is empty
const RING_ROOF_Z = -8.5;
const GAME_LIGHT_UV = { u0: 0.190, u1: 0.315, v0: 0.183, v1: 0.312 }; // where a light panel of the game hall lies in the light texture

// ---------- the stairs
const JAMB = 0.24;              // wall left between the hall and an opening
const PARTITION = 0.3;          // wall between the stairs from the ring and the first flight
const RISERS_1 = 38;            // first flight: from an opening towards the centre
const RISERS_2 = 20;            // second flight: across the hall down to the shared platform
const RISERS_3 = 14;            // exit stairs: from the shared platform down to the ring
const TREAD = 0.3;
const FLIGHT_WIDTH = 2.6;       // second flights and exit stairs
const SHARED_RADIUS = 3.0;      // the shared platform
const SLAB = 0.3;               // a free flight is this thick below its step line
const WALL_SKIRT = 0.3;         // a side wall reaches this far below the step line
const ARC_STEP = 5;             // degrees per piece of a round wall or railing
const RAIL_HEIGHT = 0.95;       // handrail above the step line
const RAIL_OFFSET = 0.08;       // handrail off the wall or the edge
const RAIL_SIZE = 0.025;        // half thickness of a handrail
const POST_EVERY = 5;           // steps between two posts of a free handrail
const MID_RAIL = 0.5;           // second bar of a railing, above the floor
const RAIL_GAP = 30;            // degrees: the script leaves the railing of the shared platform open this far to both sides of a stairs
const PANEL_WIDTH = 0.36;       // light panel in a ceiling, the size of those of the game hall
const PANEL_LENGTH = 2.0;
const PANEL_DROP = 0.02;        // a light panel hangs this far below its ceiling
const GALLERY_X = 3.5;          // the round hall is open towards a landing up to this far beside the middle
const RIB_HALF_WIDTH = 0.2;     // ribs on the wall of the round hall and beams below its ceiling
const RIB_DEPTH = 0.25;
const BEAM_DEPTH = 0.3;
const HUB_RADIUS = 1.6;         // the round light in the middle of the ceiling, where the beams meet
const BAND_TOP = 0.15;          // the light band around the wall lies this far below the ceiling
const BAND_HEIGHT = 0.3;
const LEDGE_STRIPS = 6;         // pieces of the floor between a landing and the round wall, per side

const ZONE_NEAR_Y = HALL_WALL_Y + JAMB;
const ZONE_FAR_Y = STAIR_ZONE_Y - PARTITION;
const ZONE_MID_Y = (ZONE_NEAR_Y + ZONE_FAR_Y) / 2;
const LOWER_RING_Z = RING_Z - LEVEL_SPACING;
const RISE = (CORRIDOR_Z - LOWER_RING_Z) / (RISERS_1 + RISERS_2 + RISERS_3);
const SLOPE = RISE / TREAD;
const MID_Z = CORRIDOR_Z - RISERS_1 * RISE;
const SHARED_Z = MID_Z - RISERS_2 * RISE;
const MID_CEILING_Z = MID_Z + ROOM_HEIGHT;
const FLIGHT2_X0 = -FLIGHT_WIDTH / 2;
const FLIGHT2_X1 = FLIGHT_WIDTH / 2;
const LANDING_HALF = FLIGHT2_X1;
const FLIGHT1_BOTTOM_X = LANDING_HALF;
const FLIGHT1_TOP_X = FLIGHT1_BOTTOM_X + (RISERS_1 - 1) * TREAD;
const FLIGHT2_TOP_Y = ZONE_NEAR_Y;
const FLIGHT2_BOTTOM_Y = FLIGHT2_TOP_Y - (RISERS_2 - 1) * TREAD;
const EXIT_BOTTOM = SHARED_RADIUS + (RISERS_3 - 1) * TREAD;
const DRUM_WALL_BOTTOM_Z = RING_ROOF_Z - LEVEL_SPACING;
if (FLIGHT1_TOP_X > DOOR_X - 0.2) throw new Error('the first flight starts in the opening');
if (Math.hypot(FLIGHT2_X1, FLIGHT2_BOTTOM_Y) > SHARED_RADIUS) throw new Error('a second flight misses the shared platform');
if (EXIT_BOTTOM > RING_INNER_RADIUS) throw new Error('the exit stairs reach into the ring gallery');
if (MID_Z < DRUM_WALL_BOTTOM_Z + 0.5 || MID_CEILING_Z > CORRIDOR_Z - 0.6) throw new Error('the landing does not fit between the two levels');

// Texture density of the materials of the game hall, in texture repeats per metre.
// The white wall texture of the game runs upwards, so its u axis is the height.
const MATERIALS = [
  { key: 'floor', file: GAME_MODEL_PATH + 'mat/underground_station_floor.mtl', density: 0.334 },
  { key: 'wall', file: GAME_MODEL_PATH + 'mat/underground_station_wall_3.mtl', density: 0.571, uAlongHeight: true },
  { key: 'hallWall', file: GAME_MODEL_PATH + 'mat/underground_station_wall_2.mtl', density: 0.572 },
  { key: 'ceiling', file: GAME_MODEL_PATH + 'mat/underground_station_roof.mtl', density: 0.331 },
  { key: 'rail', file: GAME_MODEL_PATH + 'mat/underground_station_railing.mtl', density: 0.08 },
  { key: 'light', file: 'mat/hub_light.mtl', density: 1 },
];
const GAME_LIGHT_MATERIAL = 'mat/underground_station_light.mtl';

// ---------- small vector helpers
const add = (a, b) => [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const scale = (a, s) => [a[0] * s, a[1] * s, a[2] * s];
const unit = (a) => scale(a, 1 / (Math.hypot(a[0], a[1], a[2]) || 1));
const radians = (degrees) => degrees * Math.PI / 180;
const onCircle = (radius, degrees, z) => [radius * Math.cos(radians(degrees)), radius * Math.sin(radians(degrees)), z];

const same = (p) => p;
const mirrorX = (p) => [-p[0], p[1], p[2]];
const mirrorY = (p) => [p[0], -p[1], p[2]];
const opposite = (p) => [-p[0], -p[1], p[2]];
const UP = [0, 0, 1], DOWN = [0, 0, -1];
const rectX = (x, y0, y1, z0, z1) => [[x, y0, z0], [x, y1, z0], [x, y1, z1], [x, y0, z1]];
const rectY = (y, x0, x1, z0, z1) => [[x0, y, z0], [x1, y, z0], [x1, y, z1], [x0, y, z1]];
const rectZ = (z, x0, x1, y0, y1) => [[x0, y0, z], [x1, y0, z], [x1, y1, z], [x0, y1, z]];

// ---------- mesh files of the game: flat number arrays, with one index list per attribute
const ATTRIBUTES = [['position', 3], ['uv0', 2], ['normal', 3], ['tangent', 4]];

function readGameFile(name) {
  return execFileSync('unzip', ['-p', GAME_ARCHIVE, GAME_MODEL_DIR + name], { maxBuffer: 1 << 28 });
}

function readMesh(mshText, blob) {
  const number = (text, key) => Number(new RegExp(key + ' = ([0-9]+)').exec(text)[1]);
  const block = (text, key) => new RegExp(key + ' = \\{[^}]*\\}').exec(text)[0];
  const attrText = mshText.slice(mshText.indexOf('vertexAttr'));
  const attrs = {};
  for (const [key] of ATTRIBUTES) {
    const b = block(attrText, key);
    attrs[key] = blob.subarray(number(b, 'offset'), number(b, 'offset') + number(b, 'count'));
  }
  const subText = mshText.slice(mshText.indexOf('subMeshes'), mshText.indexOf('vertexAttr'));
  const subMeshes = subText.split(/indices = \{/).slice(1).map((part) => {
    const lists = {};
    for (const [key] of ATTRIBUTES) {
      const b = block(part, key), offset = number(b, 'offset'), count = number(b, 'count');
      lists[key] = Array.from({ length: count / 4 }, (_, i) => blob.readUInt32LE(offset + i * 4));
    }
    return lists;
  });
  return { attrs, subMeshes };
}

function writeMesh(fileBase, mesh) {
  const parts = [];
  let offset = 0;
  const place = (buffer) => { const at = offset; parts.push(buffer); offset += buffer.length; return at; };
  const attrLines = [];
  for (const [key, numComp] of ATTRIBUTES) {
    const at = place(mesh.attrs[key]);
    attrLines.push(`\t\t${key} = { offset = ${at}, count = ${mesh.attrs[key].length}, numComp = ${numComp} },`);
  }
  const subLines = mesh.subMeshes.map((lists) => {
    const lines = ATTRIBUTES.map(([key]) => {
      const buffer = Buffer.alloc(lists[key].length * 4);
      lists[key].forEach((value, i) => buffer.writeUInt32LE(value, i * 4));
      return `\t\t\t\t${key} = { offset = ${place(buffer)}, count = ${buffer.length} },`;
    });
    return `\t\t{\n\t\t\tindices = {\n${lines.join('\n')}\n\t\t\t},\n\t\t},`;
  });
  const text = `function data()\nreturn {\n\tsubMeshes = {\n${subLines.join('\n')}\n\t},\n\tvertexAttr = {\n${attrLines.join('\n')}\n\t},\n}\nend\n`;
  fs.writeFileSync(fileBase + '.msh', text);
  fs.writeFileSync(fileBase + '.msh.blob', Buffer.concat(parts));
}

// ---------- materials of the game that read a DXT5 texture without its alpha channel
// The validation of the game asks for DXT1 where a material does not read the alpha channel of a
// texture. The mod holds a copy of each such material in mat/, and a DXT1 copy of each such
// texture in mat/tex/. A copy has the same colours as the texture of the game, bit for bit.
// With `skippedLevels` a copy starts that many mipmap levels below the largest one. The asphalt
// map of the track bed has 4096 x 4096 pixels, and its copy starts at 2048 x 2048.
const OPAQUE_MATERIALS = [
  { material: HEDGE_PATH + 'mat/Mesh_mtl_Mat.mtl', textures: ['Mesh_mtl_albo.dds', 'Mesh_mtl_mga.dds'] },
  { material: HEDGE_PATH + 'mat/hdg_02_3m_Mat.mtl', textures: ['hdg_02_3m_mga.dds'] },
  { material: GAME_MODEL_PATH + 'mat/underground_station_trackbed.mtl', textures: ['asphalt_01_metal_gloss_ao_h.dds'], skippedLevels: 1 },
  { material: '::/infrastructure/street/tram/mat/new_medium_tram_paving.mtl', textures: ['new_medium_tram_metal_gloss_ao.dds'] },
];
const ownName = (resource) => path.posix.basename(resource).toLowerCase();

// A file of the game by its resource name. Its archive is the first folder of the name that has a zip file.
function readGameResource(resource) {
  const parts = resource.replace(/^::\//, '').split('/');
  for (let depth = 1; depth < parts.length; depth++) {
    const archive = path.join(CONTENT_DIR, ...parts.slice(0, depth)) + '.zip';
    if (fs.existsSync(archive)) return execFileSync('unzip', ['-p', archive, parts.slice(depth - 1).join('/')], { maxBuffer: 1 << 28 });
  }
  throw new Error('no archive of the game holds ' + resource);
}

// A DXT5 texture as DXT1: every block keeps its colour part and loses its alpha part. The copy
// leaves out the `skippedLevels` largest mipmap levels.
function dxt5ToDxt1(dds, skippedLevels) {
  const HEADER = 128, HEIGHT = 12, WIDTH = 16, LINEAR_SIZE = 20, MIPMAPS = 28, FOURCC = 84;
  const DXT5_BLOCK = 16, DXT1_BLOCK = 8, ALPHA_PART = 8;
  if (dds.toString('ascii', FOURCC, FOURCC + 4) !== 'DXT5') throw new Error('not a DXT5 texture');
  const blocksAlong = (size, level) => Math.ceil(Math.max(1, size >> level) / 4);
  const blocksOf = (level) => blocksAlong(dds.readUInt32LE(WIDTH), level) * blocksAlong(dds.readUInt32LE(HEIGHT), level);
  const levels = Math.max(1, dds.readUInt32LE(MIPMAPS));
  if (skippedLevels >= levels) throw new Error('a texture has only ' + levels + ' mipmap levels');
  let blocks = 0, skipped = 0;
  for (let level = 0; level < levels; level++) {
    blocks += blocksOf(level);
    if (level < skippedLevels) skipped += blocksOf(level);
  }
  if (dds.length !== HEADER + blocks * DXT5_BLOCK) throw new Error('a DXT5 texture has an unexpected size');
  const out = Buffer.alloc(HEADER + (blocks - skipped) * DXT1_BLOCK);
  dds.copy(out, 0, 0, HEADER);
  out.write('DXT1', FOURCC, 'ascii');
  out.writeUInt32LE(Math.max(1, dds.readUInt32LE(WIDTH) >> skippedLevels), WIDTH);
  out.writeUInt32LE(Math.max(1, dds.readUInt32LE(HEIGHT) >> skippedLevels), HEIGHT);
  out.writeUInt32LE(levels - skippedLevels, MIPMAPS);
  out.writeUInt32LE(blocksOf(skippedLevels) * DXT1_BLOCK, LINEAR_SIZE);
  for (let i = skipped; i < blocks; i++) {
    const from = HEADER + i * DXT5_BLOCK + ALPHA_PART, to = HEADER + (i - skipped) * DXT1_BLOCK;
    const c0 = dds.readUInt16LE(from), c1 = dds.readUInt16LE(from + 2), indices = dds.readUInt32LE(from + 4);
    // DXT5 reads four colours from every block. DXT1 does so only when c0 > c1, so a block with
    // c0 < c1 gets its two colours swapped, and a block of one colour uses its first colour only.
    const swap = c0 < c1;
    out.writeUInt16LE(swap ? c1 : c0, to);
    out.writeUInt16LE(swap ? c0 : c1, to + 2);
    out.writeUInt32LE(c0 === c1 ? 0 : swap ? (indices ^ 0x55555555) >>> 0 : indices, to + 4);
  }
  return out;
}

function writeOpaqueMaterials() {
  fs.mkdirSync(path.join(OUT_DIR, 'mat', 'tex'), { recursive: true });
  for (const { material, textures, skippedLevels = 0 } of OPAQUE_MATERIALS) {
    const folder = path.posix.dirname(material) + '/';
    const copied = new Set();
    const text = readGameResource(material).toString('utf8').replace(/fileName = "([^"]+)"/g, (_, name) => {
      const resource = name.startsWith('/') ? '::' + name : folder + name;
      if (!textures.includes(path.posix.basename(name))) return 'fileName = "' + resource + '"';
      fs.writeFileSync(path.join(OUT_DIR, 'mat', 'tex', ownName(name)), dxt5ToDxt1(readGameResource(resource), skippedLevels));
      copied.add(path.posix.basename(name));
      return 'fileName = "tex/' + ownName(name) + '"';
    });
    if (copied.size !== textures.length) throw new Error(material + ' does not read every texture of its list');
    fs.writeFileSync(path.join(OUT_DIR, 'mat', ownName(material)), text);
  }
}

// The text of a model, with the material copies of this mod in place of those materials of the game.
function withOwnMaterials(model) {
  for (const { material } of OPAQUE_MATERIALS) model = model.split('"' + material + '"').join('"mat/' + ownName(material) + '"');
  return model;
}

// ---------- the hall of the game without the four corridor walls
// At the foot of the stairs from the ring a passenger turns to the platform. The wall that then
// lies ahead after one more turn is the wall that goes: it faces away from the centre of the hub.
function isDoorFace(points) {
  return points.every((p) => Math.abs(Math.abs(p[0]) - DOOR_X) < 0.01
    && Math.abs(p[1]) > HALL_WALL_Y - 0.05 && Math.abs(p[1]) < STAIR_ZONE_Y + 0.05
    && p[2] > CORRIDOR_Z - 0.05 && p[2] < CORRIDOR_Z + ROOM_HEIGHT + 0.05);
}

function removeDoorFaces(mesh) {
  const positions = mesh.attrs.position;
  let removed = 0;
  for (const lists of mesh.subMeshes) {
    const keep = [];
    for (let i = 0; i < lists.position.length; i += 3) {
      const points = [0, 1, 2].map((k) => [0, 1, 2].map((c) => positions.readFloatLE((lists.position[i + k] * 3 + c) * 4)));
      if (isDoorFace(points)) removed++; else keep.push(i);
    }
    for (const [key] of ATTRIBUTES) lists[key] = keep.flatMap((i) => lists[key].slice(i, i + 3));
  }
  return removed;
}

function buildHallWithDoors() {
  const DOORS = 4;
  const FACES_PER_DOOR = 4; // a skirting and a wall panel, two triangles each
  for (const lod of [0, 1, 2]) {
    const name = 'msh/underground_station_stairs_lod' + lod + '.msh';
    const mesh = readMesh(readGameFile(name).toString('utf8'), readGameFile(name + '.blob'));
    const removed = removeDoorFaces(mesh);
    if (removed !== DOORS * FACES_PER_DOOR) throw new Error('lod ' + lod + ': expected ' + DOORS * FACES_PER_DOOR + ' door faces, found ' + removed);
    writeMesh(path.join(OUT_DIR, 'msh', 'hall_doors_lod' + lod), mesh);
  }
  writeModelCopy('underground_station_stairs', 'hall_doors');
}

// The model file of a game model, with the meshes of this mod, the light material that is always
// on, the material copies of this mod, and the other materials taken from the game.
function writeModelCopy(gameName, name) {
  const source = readGameFile(gameName + '.mdl').toString('utf8');
  if (!source.includes('"' + GAME_LIGHT_MATERIAL + '"')) throw new Error(gameName + ' has no light material');
  const model = withOwnMaterials(source
    .split('"' + GAME_LIGHT_MATERIAL + '"').join('"mat/hub_light.mtl"')
    .replace(/"mat\/underground/g, '"' + GAME_MODEL_PATH + 'mat/underground')
    .replace(/"\/(infrastructure|assets)\//g, '"::/$1/')
    .split('msh/' + gameName + '_lod').join('msh/' + name + '_lod'));
  fs.writeFileSync(path.join(OUT_DIR, name + '.mdl'), model);
}

function buildSurfaceCopy() {
  for (const lod of [0, 1, 2]) {
    for (const extension of ['.msh', '.msh.blob']) {
      fs.writeFileSync(path.join(OUT_DIR, 'msh', 'surface_lod' + lod + extension), readGameFile('msh/underground_station_surface_lod' + lod + extension));
    }
  }
  writeModelCopy('underground_station_surface', 'surface');
}

// ---------- the back hedge of the plot
// A hedge of the game reaches 3.4 m below the ground, and the entrance stairs pass below the back
// hedge. The copy is the same hedge, with every point below HEDGE_MIN_Z lifted to that depth.
function buildBackHedge() {
  const read = (name) => execFileSync('unzip', ['-p', HEDGE_ARCHIVE, HEDGE_DIR + name], { maxBuffer: 1 << 28 });
  const COMPONENTS = 3, FLOAT_BYTES = 4, Z = 2;
  for (const lod of [0, 1, 2]) {
    const text = read(HEDGE_MESH + lod + '.msh').toString('utf8');
    const blob = Buffer.from(read(HEDGE_MESH + lod + '.msh.blob'));
    const block = /position = \{[^}]*\}/.exec(text.slice(text.indexOf('vertexAttr')))[0];
    const offset = Number(/offset = ([0-9]+)/.exec(block)[1]), count = Number(/count = ([0-9]+)/.exec(block)[1]);
    let lifted = 0;
    for (let at = offset + Z * FLOAT_BYTES; at < offset + count; at += COMPONENTS * FLOAT_BYTES) {
      if (blob.readFloatLE(at) < HEDGE_MIN_Z) { blob.writeFloatLE(HEDGE_MIN_Z, at); lifted++; }
    }
    if (lifted === 0) throw new Error('hedge lod ' + lod + ': no point below ' + HEDGE_MIN_Z);
    fs.writeFileSync(path.join(OUT_DIR, 'msh', 'back_hedge_lod' + lod + '.msh'), text);
    fs.writeFileSync(path.join(OUT_DIR, 'msh', 'back_hedge_lod' + lod + '.msh.blob'), blob);
  }
  const model = withOwnMaterials(read(HEDGE_MODEL).toString('utf8')
    .replace(/"mat\//g, '"' + HEDGE_PATH + 'mat/')
    .split(HEDGE_MESH).join('msh/back_hedge_lod'));
  for (const lod of [0, 1, 2]) {
    if (!model.includes('"msh/back_hedge_lod' + lod + '.msh"')) throw new Error('hedge model names no mesh of lod ' + lod);
  }
  fs.writeFileSync(path.join(OUT_DIR, 'back_hedge.mdl'), model);
}

// The light panels of the game hall glow only at night, as street lights do. This material is the
// same texture, always on.
function writeLightMaterial() {
  fs.mkdirSync(path.join(OUT_DIR, 'mat'), { recursive: true });
  fs.writeFileSync(path.join(OUT_DIR, 'mat', 'hub_light.mtl'), `function data()
return {
\torder = 0,
\tparams = {
\t\temissive_scale = {
\t\t\tfragmentProperties = {
\t\t\t\t{ emissiveScale = { 3, 3, 3 }, fromTime = 0, toTime = 24 },
\t\t\t},
\t\t},
\t\tlight_receiver = {
\t\t\tfragmentProperties = {
\t\t\t\t{ isLegacyMaterial = false, lightMask = 2 },
\t\t\t},
\t\t},
\t\tmap_emissive = {
\t\t\tfragmentSamplers = {
\t\t\t\temissiveTex = {
\t\t\t\t\tfileName = "${GAME_MODEL_PATH}mat/tex/street_lights_emmisive.dds",
\t\t\t\t\ttype = "TWOD",
\t\t\t\t\twrapS = "REPEAT",
\t\t\t\t\twrapT = "REPEAT",
\t\t\t\t},
\t\t\t},
\t\t},
\t},
\ttype = "EMISSIVE",
}
end
`);
}

// ---------- generated models
function makeBuilder() {
  const groups = Object.fromEntries(MATERIALS.map((m) => [m.key, { vertices: [], indices: [] }]));
  const min = [Infinity, Infinity, Infinity], max = [-Infinity, -Infinity, -Infinity];

  // A flat face that is seen from the side its normal points to. The texture follows the world axes,
  // or the corners `uvs` when they are given.
  function face(materialKey, points, normal, uvs) {
    const n = unit(normal);
    const material = MATERIALS.find((m) => m.key === materialKey);
    const vertical = Math.abs(n[2]) < 0.5;
    const along = vertical ? unit([n[1], -n[0], 0]) : [1, 0, 0];
    let uAxis = along, vAxis = vertical ? [0, 0, -1] : [0, 1, 0];
    if (vertical && material.uAlongHeight) { uAxis = [0, 0, 1]; vAxis = scale(along, -1); }
    const tangent = unit(sub(uAxis, scale(n, dot(uAxis, n))));
    const handedness = dot(cross(n, tangent), vAxis) < 0 ? -1 : 1;
    let corners = points.map((p, i) => ({ p, uv: uvs ? uvs[i] : [dot(p, uAxis) * material.density, dot(p, vAxis) * material.density] }));
    if (dot(cross(sub(points[1], points[0]), sub(points[2], points[0])), n) < 0) corners = corners.reverse();
    const group = groups[materialKey];
    const first = group.vertices.length;
    for (const { p, uv } of corners) {
      group.vertices.push({ p, uv, n, t: [...tangent, handedness] });
      for (let c = 0; c < 3; c++) { min[c] = Math.min(min[c], p[c]); max[c] = Math.max(max[c], p[c]); }
    }
    for (let i = 1; i + 1 < corners.length; i++) group.indices.push(first, first + i, first + i + 1);
  }

  // The game fails on a mesh part without faces, so a material without faces is left out.
  function toMesh() {
    const used = MATERIALS.filter((m) => groups[m.key].indices.length > 0);
    const all = used.flatMap((m) => groups[m.key].vertices);
    const pack = (numComp, get) => { const b = Buffer.alloc(all.length * numComp * 4); all.forEach((v, i) => get(v).forEach((x, c) => b.writeFloatLE(x, (i * numComp + c) * 4))); return b; };
    const attrs = { position: pack(3, (v) => v.p), uv0: pack(2, (v) => v.uv), normal: pack(3, (v) => v.n), tangent: pack(4, (v) => v.t) };
    let base = 0;
    const subMeshes = used.map((m) => {
      const indices = groups[m.key].indices.map((i) => i + base);
      base += groups[m.key].vertices.length;
      return Object.fromEntries(ATTRIBUTES.map(([key]) => [key, indices]));
    });
    return { attrs, subMeshes, materials: used.map((m) => m.file) };
  }

  return { face, toMesh, bounds: () => ({ min, max }) };
}

// A square bar between two points, such as a handrail or a post.
function bar(put, from, to) {
  const along = unit(sub(to, from));
  const side = Math.abs(along[2]) > 0.99 ? [1, 0, 0] : unit(cross(along, UP));
  const top = unit(cross(side, along));
  const corner = (p, a, b) => add(p, add(scale(side, a * RAIL_SIZE), scale(top, b * RAIL_SIZE)));
  for (const [normal, a0, b0, a1, b1] of [[side, 1, -1, 1, 1], [scale(side, -1), -1, -1, -1, 1], [top, -1, 1, 1, 1], [scale(top, -1), -1, -1, 1, -1]]) {
    put('rail', [corner(from, a0, b0), corner(to, a0, b0), corner(to, a1, b1), corner(from, a1, b1)], normal);
  }
  for (const [p, normal] of [[from, scale(along, -1)], [to, along]]) {
    put('rail', [corner(p, -1, -1), corner(p, 1, -1), corner(p, 1, 1), corner(p, -1, 1)], normal);
  }
}

// A light panel just below a ceiling: `centre` on the ceiling, `along` and `across` its two directions.
function lightPanel(put, centre, along, across, normal) {
  const a = scale(unit(along), PANEL_LENGTH / 2), b = scale(unit(across), PANEL_WIDTH / 2);
  const c = add(centre, scale(unit(normal), PANEL_DROP));
  const { u0, u1, v0, v1 } = GAME_LIGHT_UV;
  put('light', [sub(sub(c, a), b), add(sub(c, a), b), add(add(c, a), b), sub(add(c, a), b)], normal, [[u0, v0], [u0, v1], [u1, v1], [u1, v0]]);
}

// The handrails of a free flight: a rail on each side, on posts. `at(run)` gives the point on the
// step line of one side after `run` metres.
function freeHandrail(put, at, risers) {
  const lift = (p) => add(p, [0, 0, RAIL_HEIGHT]);
  const end = (risers - 1) * TREAD;
  bar(put, lift(at(0)), lift(at(end)));
  for (let i = 0; i < risers; i += POST_EVERY) {
    const run = Math.min(i * TREAD, end);
    bar(put, at(run), lift(at(run)));
  }
  bar(put, at(end), lift(at(end)));
}

// First flight: from an opening in the corridor wall towards the centre of the hub, between the
// wall of the hall and the stairs from the ring. `turn` maps the flight at +x, +y to its place.
// The coarse form has a ramp for the steps, and no handrails and no light panels.
function addFirstFlight(face, turn, coarse) {
  const put = (material, points, normal, uvs) => face(material, points.map(turn), turn(normal), uvs);
  const topCeiling = CORRIDOR_Z + ROOM_HEIGHT;
  const ceilingNormal = [CORRIDOR_Z - MID_Z, 0, -(FLIGHT1_TOP_X - FLIGHT1_BOTTOM_X)];

  put('hallWall', rectX(DOOR_X, HALL_WALL_Y, ZONE_NEAR_Y, CORRIDOR_Z, topCeiling), [1, 0, 0]);
  put('hallWall', rectX(DOOR_X, ZONE_FAR_Y, STAIR_ZONE_Y, CORRIDOR_Z, topCeiling), [1, 0, 0]);
  put('floor', rectZ(CORRIDOR_Z, FLIGHT1_TOP_X, DOOR_X, ZONE_NEAR_Y, ZONE_FAR_Y), UP);
  put('ceiling', rectZ(topCeiling, FLIGHT1_TOP_X, DOOR_X, ZONE_NEAR_Y, ZONE_FAR_Y), DOWN);
  if (coarse) {
    put('floor', [[FLIGHT1_TOP_X, ZONE_NEAR_Y, CORRIDOR_Z], [FLIGHT1_BOTTOM_X, ZONE_NEAR_Y, MID_Z],
      [FLIGHT1_BOTTOM_X, ZONE_FAR_Y, MID_Z], [FLIGHT1_TOP_X, ZONE_FAR_Y, CORRIDOR_Z]], scale(ceilingNormal, -1));
  } else {
    for (let i = 0; i < RISERS_1; i++) {
      const x = FLIGHT1_TOP_X - i * TREAD, top = CORRIDOR_Z - i * RISE;
      put('floor', rectX(x, ZONE_NEAR_Y, ZONE_FAR_Y, top - RISE, top), [-1, 0, 0]);
      if (i > 0) put('floor', rectZ(top, x, x + TREAD, ZONE_NEAR_Y, ZONE_FAR_Y), UP);
    }
  }
  // The wall towards the hall ends at GALLERY_X. From there to the landing the flight is open to
  // the round hall, above a parapet that follows the steps.
  const lineZ = (x) => MID_Z + (x - FLIGHT1_BOTTOM_X) * SLOPE;
  for (const [y, normal, railY, wallEndX] of [[ZONE_NEAR_Y, [0, 1, 0], ZONE_NEAR_Y + RAIL_OFFSET, GALLERY_X], [ZONE_FAR_Y, [0, -1, 0], ZONE_FAR_Y - RAIL_OFFSET, FLIGHT1_BOTTOM_X]]) {
    put('wall', rectY(y, FLIGHT1_TOP_X, DOOR_X, CORRIDOR_Z, topCeiling), normal);
    put('wall', [[FLIGHT1_TOP_X, y, CORRIDOR_Z - WALL_SKIRT], [wallEndX, y, lineZ(wallEndX) - WALL_SKIRT],
      [wallEndX, y, lineZ(wallEndX) + ROOM_HEIGHT], [FLIGHT1_TOP_X, y, topCeiling]], normal);
    if (!coarse) bar(put, [FLIGHT1_TOP_X, railY, CORRIDOR_Z + RAIL_HEIGHT], [FLIGHT1_BOTTOM_X, railY, MID_Z + RAIL_HEIGHT]);
  }
  for (let i = RISERS_1 - 1; FLIGHT1_TOP_X - i * TREAD < GALLERY_X; i--) {
    const x = FLIGHT1_TOP_X - i * TREAD;
    put('wall', rectY(ZONE_NEAR_Y, x, Math.min(x + TREAD, GALLERY_X), MID_Z, CORRIDOR_Z - i * RISE), [0, -1, 0]);
  }
  const POST_SPACING = 0.9;
  for (let x = FLIGHT1_BOTTOM_X + POST_SPACING / 2; !coarse && x < GALLERY_X; x += POST_SPACING) {
    bar(put, [x, ZONE_NEAR_Y + RAIL_OFFSET, lineZ(x)], [x, ZONE_NEAR_Y + RAIL_OFFSET, lineZ(x) + RAIL_HEIGHT]);
  }
  put('ceiling', [[FLIGHT1_TOP_X, ZONE_NEAR_Y, topCeiling], [FLIGHT1_BOTTOM_X, ZONE_NEAR_Y, MID_CEILING_Z],
    [FLIGHT1_BOTTOM_X, ZONE_FAR_Y, MID_CEILING_Z], [FLIGHT1_TOP_X, ZONE_FAR_Y, topCeiling]], ceilingNormal);
  for (const part of coarse ? [] : [0.25, 0.75]) {
    const x = FLIGHT1_TOP_X + (FLIGHT1_BOTTOM_X - FLIGHT1_TOP_X) * part;
    lightPanel(put, [x, ZONE_MID_Y, topCeiling + (MID_CEILING_Z - topCeiling) * part], [0, 1, 0], [FLIGHT1_TOP_X - FLIGHT1_BOTTOM_X, 0, CORRIDOR_Z - MID_Z], ceilingNormal);
  }
}

// The landing where the two first flights of one platform side meet, and the second flight: a free
// flight in the middle of the hall, down to its side of the shared platform. `turn` maps the parts of the +y side to
// their place. The coarse form has a ramp for the steps, and no handrails and no light panel.
function addLandingAndSecondFlight(face, turn, coarse) {
  const put = (material, points, normal, uvs) => face(material, points.map(turn), turn(normal), uvs);
  const drumEdgeY = (x) => Math.sqrt(RING_INNER_RADIUS * RING_INNER_RADIUS - x * x);

  put('floor', rectZ(MID_Z, -LANDING_HALF, LANDING_HALF, ZONE_NEAR_Y, ZONE_FAR_Y), UP);
  put('ceiling', rectZ(MID_CEILING_Z, -LANDING_HALF, LANDING_HALF, ZONE_NEAR_Y, ZONE_FAR_Y), DOWN);
  put('wall', rectY(ZONE_FAR_Y, -LANDING_HALF, LANDING_HALF, MID_Z, MID_CEILING_Z), [0, -1, 0]);
  // Between the landing and the round wall: a ceiling over the whole open part, and a ledge at the
  // height of the landing on both sides of the second flight.
  const strip = (x0, x1, z) => [[x0, drumEdgeY(x0), z], [x1, drumEdgeY(x1), z], [x1, ZONE_NEAR_Y, z], [x0, ZONE_NEAR_Y, z]];
  put('ceiling', strip(FLIGHT2_X0, FLIGHT2_X1, MID_CEILING_Z), DOWN);
  for (const side of [1, -1]) {
    const xs = Array.from({ length: LEDGE_STRIPS + 1 }, (_, i) => side * (FLIGHT2_X1 + (GALLERY_X - FLIGHT2_X1) * i / LEDGE_STRIPS));
    for (let i = 0; i < LEDGE_STRIPS; i++) {
      put('floor', strip(xs[i], xs[i + 1], MID_Z), UP);
      put('ceiling', strip(xs[i], xs[i + 1], MID_CEILING_Z), DOWN);
    }
    put('wall', rectX(side * GALLERY_X, drumEdgeY(GALLERY_X), ZONE_NEAR_Y, MID_Z, MID_CEILING_Z), [-side, 0, 0]);
    put('wall', rectX(side * FLIGHT2_X1, drumEdgeY(FLIGHT2_X1), ZONE_NEAR_Y, MID_Z - 2 * RISE, MID_Z), [-side, 0, 0]);
  }
  if (!coarse) lightPanel(put, [0, ZONE_MID_Y, MID_CEILING_Z], [0, 1, 0], [1, 0, 0], DOWN);

  const lineZ = (y) => MID_Z - (FLIGHT2_TOP_Y - y) * SLOPE;
  const sides = [[FLIGHT2_X0, [-1, 0, 0]], [FLIGHT2_X1, [1, 0, 0]]];
  if (coarse) {
    put('floor', [[FLIGHT2_X0, FLIGHT2_TOP_Y, MID_Z], [FLIGHT2_X1, FLIGHT2_TOP_Y, MID_Z],
      [FLIGHT2_X1, FLIGHT2_BOTTOM_Y, SHARED_Z], [FLIGHT2_X0, FLIGHT2_BOTTOM_Y, SHARED_Z]], [0, -SLOPE, 1]);
    for (const [x, normal] of sides) {
      put('wall', [[x, FLIGHT2_TOP_Y, MID_Z - SLAB], [x, FLIGHT2_BOTTOM_Y, lineZ(FLIGHT2_BOTTOM_Y) - SLAB],
        [x, FLIGHT2_BOTTOM_Y, SHARED_Z], [x, FLIGHT2_TOP_Y, MID_Z]], normal);
    }
  } else {
    for (let i = 0; i < RISERS_2; i++) {
      const y = FLIGHT2_TOP_Y - i * TREAD, top = MID_Z - i * RISE;
      put('floor', rectY(y, FLIGHT2_X0, FLIGHT2_X1, top - RISE, top), [0, -1, 0]);
      if (i > 0) {
        put('floor', rectZ(top, FLIGHT2_X0, FLIGHT2_X1, y, y + TREAD), UP);
        for (const [x, normal] of sides) {
          put('wall', [[x, y, lineZ(y) - SLAB], [x, y + TREAD, lineZ(y + TREAD) - SLAB], [x, y + TREAD, top], [x, y, top]], normal);
        }
      }
    }
  }
  put('wall', [[FLIGHT2_X0, FLIGHT2_TOP_Y, MID_Z - SLAB], [FLIGHT2_X1, FLIGHT2_TOP_Y, MID_Z - SLAB],
    [FLIGHT2_X1, FLIGHT2_BOTTOM_Y, lineZ(FLIGHT2_BOTTOM_Y) - SLAB], [FLIGHT2_X0, FLIGHT2_BOTTOM_Y, lineZ(FLIGHT2_BOTTOM_Y) - SLAB]], [0, SLOPE, -1]);
  for (const x of coarse ? [] : [FLIGHT2_X0 + RAIL_OFFSET, FLIGHT2_X1 - RAIL_OFFSET]) {
    freeHandrail(put, (run) => [x, FLIGHT2_TOP_Y - run, MID_Z - run * SLOPE], RISERS_2);
    joinPlatformRailing(put, [x, FLIGHT2_BOTTOM_Y, SHARED_Z], RISE);
  }
}

// Two bars from the end of a handrail on the shared platform to the place where the railing of the
// platform ends. `foot` is the foot of the last post of the handrail, on the +y side of the
// platform, and `lift` the height of its last step above the platform.
function joinPlatformRailing(put, foot, lift) {
  const railEnd = onCircle(SHARED_RADIUS - RAIL_OFFSET, 90 - Math.sign(foot[0]) * RAIL_GAP, SHARED_Z);
  bar(put, add(foot, [0, 0, lift + RAIL_HEIGHT]), add(railEnd, [0, 0, RAIL_HEIGHT]));
  bar(put, add(foot, [0, 0, MID_RAIL]), add(railEnd, [0, 0, MID_RAIL]));
}

// The round hall inside the ring of the lower level: a floor level with the ring, a ceiling, a wall
// above the roof of the ring, and the shared platform in the middle. Towards each landing the wall
// ends at the height of the landing, so the landings look into the hall. Ribs on the wall meet
// beams below the ceiling, and the beams meet at a round light in the middle. A light band runs
// around the top of the wall. The coarse form has no light panels between the beams.
function addDrum(face, coarse) {
  for (let a = 0; a < 360; a += ARC_STEP) {
    const fan = (radius, z) => [[0, 0, z], onCircle(radius, a, z), onCircle(radius, a + ARC_STEP, z)];
    face('floor', fan(RING_INNER_RADIUS, LOWER_RING_Z), UP);
    face('ceiling', fan(RING_INNER_RADIUS, MID_CEILING_Z), DOWN);
    face('floor', fan(SHARED_RADIUS, SHARED_Z), UP);
    face('wall', [onCircle(SHARED_RADIUS, a, LOWER_RING_Z), onCircle(SHARED_RADIUS, a + ARC_STEP, LOWER_RING_Z),
      onCircle(SHARED_RADIUS, a + ARC_STEP, SHARED_Z), onCircle(SHARED_RADIUS, a, SHARED_Z)], onCircle(1, a + ARC_STEP / 2, 0));
  }
  const wallPiece = (a0, a1, z0, z1) => face('wall', [onCircle(RING_INNER_RADIUS, a0, z0), onCircle(RING_INNER_RADIUS, a1, z0),
    onCircle(RING_INNER_RADIUS, a1, z1), onCircle(RING_INNER_RADIUS, a0, z1)], scale(onCircle(1, (a0 + a1) / 2, 0), -1));
  const arc = (from, to, z0, z1) => {
    const pieces = Math.ceil((to - from) / ARC_STEP);
    for (let i = 0; i < pieces; i++) wallPiece(from + (to - from) * i / pieces, from + (to - from) * (i + 1) / pieces, z0, z1);
  };
  const doorStart = Math.acos(FLIGHT2_X1 / RING_INNER_RADIUS) * 180 / Math.PI;
  const doorEnd = Math.acos(FLIGHT2_X0 / RING_INNER_RADIUS) * 180 / Math.PI;
  const SILL_BELOW_MID = 0.45; // the wall under an opening ends below the first steps of the second flight
  const galleryStart = Math.acos(GALLERY_X / RING_INNER_RADIUS) * 180 / Math.PI;
  const galleryEnd = 180 - galleryStart;
  const { u0, u1, v0, v1 } = GAME_LIGHT_UV;
  const lightUvs = [[u0, v0], [u1, v0], [u1, v1], [u0, v1]];
  const bandRadius = RING_INNER_RADIUS - PANEL_DROP;
  const bandTop = MID_CEILING_Z - BAND_TOP, bandBottom = bandTop - BAND_HEIGHT;
  for (const turn of [0, 180]) {
    arc(galleryEnd + turn, galleryStart + turn + 180, DRUM_WALL_BOTTOM_Z, MID_CEILING_Z);
    arc(galleryStart + turn, doorStart + turn, DRUM_WALL_BOTTOM_Z, MID_Z);
    arc(doorEnd + turn, galleryEnd + turn, DRUM_WALL_BOTTOM_Z, MID_Z);
    arc(doorStart + turn, doorEnd + turn, DRUM_WALL_BOTTOM_Z, MID_Z - SILL_BELOW_MID);
    for (let a = galleryEnd + turn; a < galleryStart + turn + 180; a += ARC_STEP) {
      face('light', [onCircle(bandRadius, a, bandBottom), onCircle(bandRadius, a + ARC_STEP, bandBottom),
        onCircle(bandRadius, a + ARC_STEP, bandTop), onCircle(bandRadius, a, bandTop)], scale(onCircle(1, a + ARC_STEP / 2, 0), -1), lightUvs);
    }
  }

  // A rib or a beam at direction a: a box that stands RIB_HALF_WIDTH to both sides of that direction.
  const RIB_STEP = 30;
  const at = (a, along, across, z) => add(scale(onCircle(1, a, 0), along), add(scale(onCircle(1, a + 90, 0), across), [0, 0, z]));
  const beamBottom = MID_CEILING_Z - BEAM_DEPTH;
  for (let a = 0; a < 360; a += RIB_STEP) {
    const inner = RING_INNER_RADIUS - RIB_DEPTH;
    const inOpening = (a % 180) > galleryStart && (a % 180) < galleryEnd;
    if (!inOpening) {
      face('hallWall', [at(a, inner, -RIB_HALF_WIDTH, DRUM_WALL_BOTTOM_Z), at(a, inner, RIB_HALF_WIDTH, DRUM_WALL_BOTTOM_Z),
        at(a, inner, RIB_HALF_WIDTH, beamBottom), at(a, inner, -RIB_HALF_WIDTH, beamBottom)], scale(onCircle(1, a, 0), -1));
      for (const side of [1, -1]) {
        face('hallWall', [at(a, inner, side * RIB_HALF_WIDTH, DRUM_WALL_BOTTOM_Z), at(a, RING_INNER_RADIUS, side * RIB_HALF_WIDTH, DRUM_WALL_BOTTOM_Z),
          at(a, RING_INNER_RADIUS, side * RIB_HALF_WIDTH, beamBottom), at(a, inner, side * RIB_HALF_WIDTH, beamBottom)], scale(onCircle(1, a + 90, 0), side));
      }
      face('hallWall', [at(a, inner, -RIB_HALF_WIDTH, DRUM_WALL_BOTTOM_Z), at(a, inner, RIB_HALF_WIDTH, DRUM_WALL_BOTTOM_Z),
        at(a, RING_INNER_RADIUS, RIB_HALF_WIDTH, DRUM_WALL_BOTTOM_Z), at(a, RING_INNER_RADIUS, -RIB_HALF_WIDTH, DRUM_WALL_BOTTOM_Z)], DOWN);
    }
    face('ceiling', [at(a, HUB_RADIUS, -RIB_HALF_WIDTH, beamBottom), at(a, RING_INNER_RADIUS, -RIB_HALF_WIDTH, beamBottom),
      at(a, RING_INNER_RADIUS, RIB_HALF_WIDTH, beamBottom), at(a, HUB_RADIUS, RIB_HALF_WIDTH, beamBottom)], DOWN);
    for (const side of [1, -1]) {
      face('ceiling', [at(a, HUB_RADIUS, side * RIB_HALF_WIDTH, beamBottom), at(a, RING_INNER_RADIUS, side * RIB_HALF_WIDTH, beamBottom),
        at(a, RING_INNER_RADIUS, side * RIB_HALF_WIDTH, MID_CEILING_Z), at(a, HUB_RADIUS, side * RIB_HALF_WIDTH, MID_CEILING_Z)], scale(onCircle(1, a + 90, 0), side));
    }
    if (!coarse) lightPanel(face, onCircle((HUB_RADIUS + RING_INNER_RADIUS) / 2, a + RIB_STEP / 2, MID_CEILING_Z), onCircle(1, a + RIB_STEP / 2, 0), onCircle(1, a + RIB_STEP / 2 + 90, 0), DOWN);
  }
  for (let a = 0; a < 360; a += ARC_STEP) {
    face('light', [[0, 0, beamBottom], onCircle(HUB_RADIUS, a, beamBottom), onCircle(HUB_RADIUS, a + ARC_STEP, beamBottom)], DOWN, [[u0, v0], [u1, v0], [u1, v1]]);
    face('ceiling', [onCircle(HUB_RADIUS, a, beamBottom), onCircle(HUB_RADIUS, a + ARC_STEP, beamBottom),
      onCircle(HUB_RADIUS, a + ARC_STEP, MID_CEILING_Z), onCircle(HUB_RADIUS, a, MID_CEILING_Z)], onCircle(1, a + ARC_STEP / 2, 0));
  }
}

// The two stairs from the shared platform down to the ring, along +y and -y of this model. The
// script turns the model so that they point to the exits of the ring where the second flights
// leave room for that.
function addExitStairs(face) {
  const half = FLIGHT_WIDTH / 2;
  const edge = Math.sqrt(SHARED_RADIUS * SHARED_RADIUS - half * half); // where the round platform ends at the side of a flight
  for (const turn of [same, opposite]) {
    const put = (material, points, normal) => face(material, points.map(turn), turn(normal));
    put('floor', rectZ(SHARED_Z, -half, half, edge, SHARED_RADIUS), UP);
    for (const [x, normal] of [[-half, [-1, 0, 0]], [half, [1, 0, 0]]]) put('wall', rectX(x, edge, SHARED_RADIUS, LOWER_RING_Z, SHARED_Z), normal);
    for (let i = 0; i < RISERS_3; i++) {
      const y = SHARED_RADIUS + i * TREAD, top = SHARED_Z - i * RISE;
      put('floor', rectY(y, -half, half, top - RISE, top), [0, 1, 0]);
      if (i > 0) {
        put('floor', rectZ(top, -half, half, y - TREAD, y), UP);
        for (const [x, normal] of [[-half, [-1, 0, 0]], [half, [1, 0, 0]]]) put('wall', rectX(x, y - TREAD, y, LOWER_RING_Z, top), normal);
      }
    }
    for (const x of [-half + RAIL_OFFSET, half - RAIL_OFFSET]) {
      freeHandrail(put, (run) => [x, SHARED_RADIUS + run, SHARED_Z - run * SLOPE], RISERS_3);
      joinPlatformRailing(put, [x, SHARED_RADIUS, SHARED_Z], 0);
    }
  }
}

// One piece of the railing around the shared platform, from 0 to ARC_STEP degrees.
function addPlatformRail(face) {
  const radius = SHARED_RADIUS - RAIL_OFFSET;
  for (const height of [RAIL_HEIGHT, MID_RAIL]) bar(face, onCircle(radius, 0, SHARED_Z + height), onCircle(radius, ARC_STEP, SHARED_Z + height));
  bar(face, onCircle(radius, ARC_STEP / 2, SHARED_Z), onCircle(radius, ARC_STEP / 2, SHARED_Z + RAIL_HEIGHT));
}

// The four corridor walls that hall_doors.mdl lacks.
function addDoorPlugs(face) {
  for (const turn of [same, mirrorX, mirrorY, opposite]) {
    face('hallWall', rectX(DOOR_X, HALL_WALL_Y, STAIR_ZONE_Y, CORRIDOR_Z, CORRIDOR_Z + ROOM_HEIGHT).map(turn), turn([1, 0, 0]));
  }
}

function lightBlock(name, position) {
  return `\t\t\t\t\t{
\t\t\t\t\t\tcolor = { 1, 0.913746, 0.598039, },
\t\t\t\t\t\tfadeOutStart = 400,
\t\t\t\t\t\tinvertMask = true,
\t\t\t\t\t\tlightId = "",
\t\t\t\t\t\tmask = 0,
\t\t\t\t\t\tmeshId = "${name}",
\t\t\t\t\t\tmode = "LIGHT",
\t\t\t\t\t\tradius = 9,
\t\t\t\t\t\tstrength = 0.6,
\t\t\t\t\t\ttransf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, ${position.map((v) => v.toFixed(3)).join(', ')}, 1, },
\t\t\t\t\t\ttype = "POINT",
\t\t\t\t\t\tvisibleFrom = -1,
\t\t\t\t\t\tvisibleTo = 500,
\t\t\t\t\t},`;
}

// The validation of the game allows this much mesh data in the lowest detail level of a model.
const WORST_LEVEL_LIMIT = 256 * 1024;
const VISIBLE_TO = 6000;

// `build(face, coarse)` adds the faces of the model. With `coarseFrom` the model has a second
// detail level, the coarse form, which the game shows from that distance in metres.
function writeModel(name, build, lights, coarseFrom) {
  const levels = (coarseFrom ? [false, true] : [false]).map((coarse) => {
    const builder = makeBuilder();
    build(builder.face, coarse);
    const mesh = builder.toMesh();
    const file = name + (coarse ? '_coarse' : '');
    writeMesh(path.join(OUT_DIR, 'msh', file), mesh);
    return { builder, mesh, file, from: coarse ? coarseFrom : 0, to: coarse || !coarseFrom ? VISIBLE_TO : coarseFrom };
  });
  const worst = fs.statSync(path.join(OUT_DIR, 'msh', levels[levels.length - 1].file + '.msh.blob')).size;
  if (worst > WORST_LEVEL_LIMIT) throw new Error(name + ': the lowest detail level has ' + worst + ' bytes of mesh data');
  const { min, max } = levels[0].builder.bounds();
  const list = (v) => v.map((x) => x.toFixed(4)).join(', ');
  const metadata = lights.length === 0 ? '\tmetadata = {},' : `\tmetadata = {
\t\tlightSourceList = {
\t\t\tlights = {
${lights.map((position) => lightBlock(name, position)).join('\n')}
\t\t\t},
\t\t},
\t},`;
  fs.writeFileSync(path.join(OUT_DIR, name + '.mdl'), `function data()
return {
\tboundingInfo = {
\t\tbbMax = { ${list(max)} },
\t\tbbMin = { ${list(min)} },
\t},
\tcollider = {
\t\ttype = "NONE",
\t},
\tlods = {
${levels.map((level) => `\t\t{
\t\t\tnode = {
\t\t\t\tchildren = {
\t\t\t\t\t{
\t\t\t\t\t\tmaterials = { ${level.mesh.materials.map((file) => '"' + file + '"').join(', ')} },
\t\t\t\t\t\tmesh = "msh/${level.file}.msh",
\t\t\t\t\t\tname = "${name}",
\t\t\t\t\t\ttransf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 },
\t\t\t\t\t},
\t\t\t\t},
\t\t\t\tname = "RootNode",
\t\t\t\ttransf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 },
\t\t\t},
\t\t\tvisibleFrom = ${level.from},
\t\t\tvisibleTo = ${level.to},
\t\t},`).join('\n')}
\t},
${metadata}
\tversion = 2,
}
end
`);
}

fs.mkdirSync(path.join(OUT_DIR, 'msh'), { recursive: true });
writeLightMaterial();
writeOpaqueMaterials();
buildHallWithDoors();
buildSurfaceCopy();
buildBackHedge();

const LIGHT_DROP = 0.5; // a light source hangs this far below its ceiling
const flightLight = [(FLIGHT1_TOP_X + FLIGHT1_BOTTOM_X) / 2, ZONE_MID_Y, (CORRIDOR_Z + MID_Z) / 2 + ROOM_HEIGHT - LIGHT_DROP];
const landingLight = [0, ZONE_MID_Y, MID_CEILING_Z - LIGHT_DROP];
const drumLight = [4.5, 0, MID_CEILING_Z - LIGHT_DROP];
const STAIRS_COARSE_FROM = 300; // metres: from here the game shows the stairs without steps, handrails and light panels
writeModel('level_stairs', (face, coarse) => {
  for (const turn of [same, mirrorX, mirrorY, opposite]) addFirstFlight(face, turn, coarse);
  for (const turn of [same, opposite]) addLandingAndSecondFlight(face, turn, coarse);
  addDrum(face, coarse);
}, [...[same, mirrorX, mirrorY, opposite].map((turn) => turn(flightLight)), ...[same, opposite].flatMap((turn) => [turn(landingLight), turn(drumLight)])], STAIRS_COARSE_FROM);
writeModel('exit_stairs', addExitStairs, []);
writeModel('platform_rail', addPlatformRail, []);
writeModel('hall_door_plugs', addDoorPlugs, []);

// The walkway of the stairs in hub_script.lua uses these numbers.
console.log('stair models written to ' + OUT_DIR);
console.log(JSON.stringify({
  flight1TopX: +FLIGHT1_TOP_X.toFixed(3), flight1BottomX: +FLIGHT1_BOTTOM_X.toFixed(3), zoneY: +ZONE_MID_Y.toFixed(3),
  flight2TopY: FLIGHT2_TOP_Y, flight2BottomY: +FLIGHT2_BOTTOM_Y.toFixed(3),
  midZ: +MID_Z.toFixed(4), sharedZ: +SHARED_Z.toFixed(4), sharedRadius: SHARED_RADIUS, exitBottom: +EXIT_BOTTOM.toFixed(3), lowerRingZ: LOWER_RING_Z,
  secondFlightSector: [+(Math.atan2(FLIGHT2_BOTTOM_Y, FLIGHT2_X1) * 180 / Math.PI).toFixed(1), +(Math.atan2(Math.sqrt(SHARED_RADIUS ** 2 - FLIGHT2_X0 ** 2), FLIGHT2_X0) * 180 / Math.PI).toFixed(1)],
  exitHalfAngle: +(Math.asin(FLIGHT_WIDTH / 2 / SHARED_RADIUS) * 180 / Math.PI).toFixed(1),
}));
