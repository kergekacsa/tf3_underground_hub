// Builds strings.json for the 13 languages of the game.
// A word that the game has is taken from the catalogue of the game, so the station uses the same
// words as the game. Only the sentences and the names are translated here.
// Run in kacsa_underground_hub_dev: node tools/build_strings.js
// The catalogues are read from the game, so the game MUST be installed.
const fs = require('fs');
const path = require('path');

const GAME_STRINGS = process.env.TF3_STRINGS
  || 'C:/Program Files (x86)/Steam/steamapps/common/Transport Fever 3/base/strings';
const OUT_FILE = path.join(__dirname, '..', '..', 'kacsa_underground_hub', 'strings.json');
const LANGUAGES = ['en', 'de', 'es', 'fr', 'it', 'ja', 'ko', 'nl', 'pl', 'pt_BR', 'ru', 'zh_CN', 'zh_TW'];
const LEVELS = [1, 2, 3, 4];
const CONTEXT = '\u0004'; // gettext joins a message context and a message with this character

// ---------- the catalogue of the game: a gettext .mo file, message id to translation
function readCatalogue(language) {
  const data = fs.readFileSync(path.join(GAME_STRINGS, language, 'LC_MESSAGES', 'base.mo'));
  const count = data.readUInt32LE(8), ids = data.readUInt32LE(12), texts = data.readUInt32LE(16);
  const entry = (table, index) => data.toString('utf8', data.readUInt32LE(table + index * 8 + 4),
    data.readUInt32LE(table + index * 8 + 4) + data.readUInt32LE(table + index * 8));
  const catalogue = new Map();
  for (let index = 0; index < count; index++) catalogue.set(entry(ids, index), entry(texts, index));
  return catalogue;
}

// ---------- words of the game: string key to the message id of the game
const GAME_WORDS = {
  HUB_CARGO_MODE: 'Mode',
  HUB_CARGO_PASSENGER: 'layer-infrastructure-areas' + CONTEXT + 'Passengers',
  HUB_CARGO_CARGO: 'layer-infrastructure-areas' + CONTEXT + 'Cargo',
  HUB_CARGO_MIXED: 'Mixed',
  HUB_VEHICLE_RAIL: 'carrier' + CONTEXT + 'Rail',
  HUB_VEHICLE_TRAM: 'carrier' + CONTEXT + 'Tram',
  HUB_VEHICLE_OFF: 'graphics-quality-settings' + CONTEXT + 'Off',
  HUB_LEVEL_VEHICLE: 'Vehicle',
  HUB_LEVEL_LENGTH: 'Length',
};
// The game has the word for an angle only inside this message, in front of a colon.
const ANGLE_MESSAGE = 'Angle: {angle}°';
const levelMessage = (level) => 'Level ' + level;
// In these languages the game's word for "Level" means a rank, not a floor.
const FLOOR_TITLE = { zh_CN: (level) => '第 ' + level + ' 层', zh_TW: (level) => '第 ' + level + ' 層' };

// ---------- texts of this mod
const ENGLISH = {
  HUB_UNDERGROUND_RAIL_NAME: 'Underground Transfer Hub',
  HUB_UNDERGROUND_RAIL_DESC: 'Underground station with one to four stacked levels: rail or tram on each level, each with two tracks. Every level has its own angle and length. Passenger, cargo or mixed operation. Platform lengths of 40, 80, 120, 160, 240 or 320 m. The station can be reconfigured at any time after construction.',
  HUB_CARGO_MODE: 'Operation',
  HUB_CARGO_PASSENGER: 'Passenger',
  HUB_CARGO_CARGO: 'Cargo',
  HUB_CARGO_MIXED: 'Mixed',
  HUB_VEHICLE_RAIL: 'Rail',
  HUB_VEHICLE_TRAM: 'Tram',
  HUB_VEHICLE_OFF: 'Off',
  HUB_LEVEL_VEHICLE: 'Vehicle',
  HUB_LEVEL_ANGLE: 'Angle',
  HUB_LEVEL_LENGTH: 'Length',
};
const ENGLISH_LOCKED = 'tracks are connected. It cannot be changed.';
// The name of a new station. The English text is the message id, so English has no entry.
const STATION_NAME_ID = '{townName} Underground Station';

// name: the name in the construction menu, with the game's word for a transfer from its message
// "{stationName} Transfer". Simplified Chinese uses the word of the source mod instead. station: the name of a new station, after the pattern
// of the game's "{townName} Underground Stop". separator and locked: the note of a connected level,
// "<Level n><separator><locked>".
const OWN = {
  de: {
    name: 'Unterirdischer Transfer-Hub',
    station: '{townName} Unterirdische Station',
    separator: ': ', locked: 'Gleise sind angeschlossen. Keine Änderung möglich.',
    desc: 'Unterirdische Station mit einem bis vier übereinanderliegenden Levels: Schiene oder Tram pro Level, jeweils mit zwei Gleisen. Jedes Level hat einen eigenen Winkel und eine eigene Länge. Betrieb für Passagiere, Güter oder gemischt. Plattformlängen von 40, 80, 120, 160, 240 oder 320 m. Die Station lässt sich nach dem Bau jederzeit umbauen.',
  },
  es: {
    name: 'Hub de trasbordo subterráneo',
    station: 'Estación subterránea de {townName}',
    separator: ': ', locked: 'hay vías conectadas. No se puede modificar.',
    desc: 'Estación subterránea con uno a cuatro niveles superpuestos: raíl o tranvía en cada nivel, cada uno con dos vías. Cada nivel tiene su propio ángulo y su propia longitud. Funcionamiento de pasajeros, de cargamento o mixto. Longitudes de plataforma de 40, 80, 120, 160, 240 o 320 m. La estación se puede reconfigurar en cualquier momento después de construirla.',
  },
  fr: {
    name: 'Hub de correspondance souterrain',
    station: 'Gare souterraine de {townName}',
    separator: ' : ', locked: 'des voies sont raccordées. Il ne peut pas être modifié.',
    desc: 'Gare souterraine de un à quatre niveaux superposés : rail ou tramway à chaque niveau, chacun avec deux voies. Chaque niveau a son propre angle et sa propre longueur. Exploitation passagers, fret ou mixte. Longueurs de quai de 40, 80, 120, 160, 240 ou 320 m. La gare peut être reconfigurée à tout moment après sa construction.',
  },
  it: {
    name: 'Hub di transito sotterraneo',
    station: 'Stazione sotterranea di {townName}',
    separator: ': ', locked: 'ci sono binari collegati. Non può essere modificato.',
    desc: 'Stazione sotterranea con da uno a quattro livelli sovrapposti: ferrovia o tram per ogni livello, ciascuno con due binari. Ogni livello ha angolazione e lunghezza proprie. Esercizio passeggeri, carico o misto. Lunghezze della piattaforma di 40, 80, 120, 160, 240 o 320 m. La stazione può essere riconfigurata in qualsiasi momento dopo la costruzione.',
  },
  ja: {
    name: '地下乗換ハブ',
    station: '{townName}地下駅',
    separator: '：', locked: '線路が接続されています。変更できません。',
    desc: '1～4層のレベルを重ねた地下駅。レベルごとに鉄道または路面電車を選べ、各レベルに線路が2本あります。レベルごとに角度と長さを設定できます。旅客、貨物、複合の運用に対応。プラットフォームの長さは40、80、120、160、240、320 m。建設後もいつでも設定を変更できます。',
  },
  ko: {
    name: '지하 환승 허브',
    station: '{townName} 지하 역',
    separator: ': ', locked: '선로가 연결되어 있습니다. 변경할 수 없습니다.',
    desc: '1~4개의 레벨을 쌓은 지하 역입니다. 레벨마다 철도 또는 전차를 고를 수 있고, 각 레벨에는 선로가 2개 있습니다. 레벨마다 각도와 길이를 따로 정할 수 있습니다. 승객, 화물 또는 혼합 운영. 플랫폼 길이는 40, 80, 120, 160, 240, 320 m입니다. 건설 후에도 언제든지 다시 설정할 수 있습니다.',
  },
  nl: {
    name: 'Ondergrondse transferhub',
    station: 'Ondergronds station {townName}',
    separator: ': ', locked: 'er zijn sporen aangesloten. Wijzigen is niet mogelijk.',
    desc: 'Ondergronds station met één tot vier gestapelde niveaus: spoor of tram per niveau, elk met twee sporen. Elk niveau heeft een eigen hoek en lengte. Gebruik voor reizigers, vracht of gemengd. Perronlengtes van 40, 80, 120, 160, 240 of 320 m. Het station kan na de bouw altijd opnieuw worden ingesteld.',
  },
  pl: {
    name: 'Podziemny hub transferowy',
    station: 'Dworzec podziemny {townName}',
    separator: ': ', locked: 'tory są połączone. Nie można go zmienić.',
    desc: 'Dworzec podziemny z jednym do czterech poziomów ułożonych jeden nad drugim: kolej lub tramwaj na każdym poziomie, każdy z dwoma torami. Każdy poziom ma własny kąt i długość. Tryb pasażerski, towarowy lub mieszany. Długości peronu: 40, 80, 120, 160, 240 lub 320 m. Dworzec można przebudować w dowolnym momencie po budowie.',
  },
  pt_BR: {
    name: 'Hub de Transferência Subterrâneo',
    station: 'Estação Subterrânea de {townName}',
    separator: ': ', locked: 'há trilhos conectados. Não pode ser alterado.',
    desc: 'Estação subterrânea com um a quatro níveis empilhados: ferrovia ou bonde em cada nível, cada um com dois trilhos. Cada nível tem seu próprio ângulo e comprimento. Operação de passageiros, de carga ou mista. Comprimentos de plataforma de 40, 80, 120, 160, 240 ou 320 m. A estação pode ser reconfigurada a qualquer momento após a construção.',
  },
  ru: {
    name: 'Подземный трансферный хаб',
    station: '{townName} Станция подземки',
    separator: ': ', locked: 'пути подключены. Изменение невозможно.',
    desc: 'Подземная станция с количеством уровней от одного до четырёх, расположенных друг над другом: рельсы или трамвай на каждом уровне, на каждом по два пути. У каждого уровня свои угол и длина. Пассажирский, грузовой или смешанный режим. Длина платформы: 40, 80, 120, 160, 240 или 320 м. Станцию можно перенастроить в любое время после постройки.',
  },
  zh_CN: {
    name: '地下换乘枢纽',
    station: '{townName} 地下站',
    separator: '：', locked: '轨道已连接，无法更改。',
    desc: '地下车站，可叠加 1 至 4 层：每层可选铁路或有轨电车，各有两条轨道。每层可单独设置角度和长度。支持乘客、货物或混合运营。月台长度可选 40、80、120、160、240 或 320 米。建成后可随时重新配置。',
  },
  zh_TW: {
    name: '地下轉運樞紐',
    station: '{townName}地下站',
    separator: '：', locked: '軌道已連接，無法變更。',
    desc: '地下車站，可疊加 1 至 4 層：每層可選鐵道或輕軌，各有兩條軌道。每層可單獨設定角度和長度。支援乘客、貨物或混合營運。月台長度可選 40、80、120、160、240 或 320 公尺。建成後可隨時重新配置。',
  },
};

function english() {
  const strings = { ...ENGLISH };
  for (const level of LEVELS) strings['HUB_LEVEL_' + level + '_LOCKED'] = levelMessage(level) + ': ' + ENGLISH_LOCKED;
  for (const level of LEVELS) strings['HUB_LEVEL_' + level + '_TITLE'] = levelMessage(level);
  return strings;
}

function translated(language) {
  const catalogue = readCatalogue(language), own = OWN[language];
  const gameWord = (id) => {
    const word = catalogue.get(id);
    if (!word) throw new Error(language + ': the game has no translation of ' + JSON.stringify(id));
    return word;
  };
  const levelTitle = (level) => (FLOOR_TITLE[language] ? FLOOR_TITLE[language](level) : gameWord(levelMessage(level)));
  const strings = {
    HUB_UNDERGROUND_RAIL_NAME: own.name,
    HUB_UNDERGROUND_RAIL_DESC: own.desc,
    [STATION_NAME_ID]: own.station,
  };
  for (const [key, id] of Object.entries(GAME_WORDS)) strings[key] = gameWord(id);
  strings.HUB_LEVEL_ANGLE = gameWord(ANGLE_MESSAGE).split(/[:：]/)[0].trim();
  for (const level of LEVELS) strings['HUB_LEVEL_' + level + '_LOCKED'] = levelTitle(level) + own.separator + own.locked;
  for (const level of LEVELS) strings['HUB_LEVEL_' + level + '_TITLE'] = levelTitle(level);
  return strings;
}

const result = {};
for (const language of LANGUAGES) result[language] = language === 'en' ? english() : translated(language);
fs.writeFileSync(OUT_FILE, JSON.stringify(result, null, 2) + '\n');
console.log('strings written for ' + LANGUAGES.length + ' languages to ' + OUT_FILE);
