
# Mini-framework Game Jam-ekhez!

## Love2D rövidítések
A `love_aliases.lua` modulban célszerű megadni globális Love2D könyvtár rövidítéseket, ami alapból ezeket tartalmazza:

- `LG`: `love.graphics`
- `LA`: `love.audio`
- `LK`: `love.keyboard`

## State Management

A játék részeit külön "State"-ekre bontjuk, amiket az alábbi "class" modellez:

- `init: fun()`
- `update: fun()`
- `draw: fun(alpha: number)`

> A következő bemenet kezelési mezőket megadni **opcionális**.

- `mouseMoved: nil | fun(x: number, y: number, dx: number, dy: number, isTouch: boolean)`
- `mousePressed: nil | fun(x: number, y: number, button: number, isTouch: boolean)`
- `mouseReleased: nil | fun(x: number, y: number, button: number, isTouch: boolean)`
- `keyPressed: nil | fun(key: love.KeyConstant, scancode: love.Scancode, isRepeat: boolean)`
- `keyReleased: nil | fun(key: love.KeyConstant, scancode: love.Scancode)`


Egyszerre mindig csak egy State lehet aktív (plusz egy speciális, a `background.lua`-ban definiált State ami a scalelt kijelző körülötti üres teret tölti ki), és **változtatni a `ChangeState(s: State)` függvénnyel lehet, ami autómatikusan meghívja az adott `init()` függvényt is.**

Minden State-t **kötelező hozzáadni a `states.lua` fájlhoz, hogy globálisan elérhető legyen.

### Példaként szolgálnak a `title` és `game` State-k a megfelelő mappákban.

---

## Resources

Az erőforrások könnyebb kezelése érdekében ezeket globális változókban tároljuk, és a megfelelő fájlba kell beírni őket `resources/` mappába.

Hanganyagokat az `audio.lua` fájlba kell megírni: a hangeffektek az `SFX` táblába, a háttérzene pedig a `BGM` táblába kerül. Ezeket az új `NewBGM` és `NewSFX` függvényekkel célszerű létrehozni: 

```lua
BGM = {
    menu = NewBGM("random_fajlnev.wav"),
    gameOver = NewBGM("valami_zene2.wav"),
    -- stb stb
}

SFX = {
    ugras = NewSFX("valami_effekt.wav"),
    coin = NewSFX("bullshit_fajlnev.wav"),
    -- stb stb
}

```
Ezeket célszerű az új `Audio(source: love.Source)` wrapper-el használni, mivel ezzel a **nem betölthető hangfájlokat szokványos módon kezeljük**, így nem kell átírni a kódot ha meglesz a konkrét fájl:

```lua
SFX = {
    -- Még nincs ugrás hangeffekt!
    ugras = nil
}

-- valahol máshol --

SFX.ugras:play() -- CRASH!!

Audio(SFX.ugras):play() -- Nincs hiba, csak csend!
```

A képi erőforrások a `sprites.lua` fájlba mennek, és két féle módon lehet alkalmazni a fájlt:

1. Spritesheet használatával

```lua
SPRITESHEET = LG.newImage("spritesheet_fajl.png")

-- A SPRITES Quad-okat tárol
SPRITES = {
    upWall = LG.newQuad(0, 0, 16, 16, ...)
    leftWall = LG.newQuad(16, 0, 16, 16, ...)
    -- stb stb
}
```

2. Külön sprite-ok használatával

```lua
SPRITESHEET = nil  -- muszáj nil-nek lenni!

-- A SPRITES Image-eket tartalmaz
SPRITES = {
    upWall = LG.newImage("upwall.png")
    leftWall = LG.newImage("leftwall.png")
}
```

Ezeknek rugalmas kezeléséhez használjuk az új `LG.spr()` függvényt, ami automatikusan kezeli mindkét féle rajzolást:

```lua
LG.spr(SPRITES.upWall, x, y)
```

Sosem kell használni a spritesheet-et, mindkét esetben elég a sprite-ot megadni. A `spr()` függvény továbbá **nem pánikol, ha nem létező sprite-ot kéne rajzolni, helyette egy piros placeholder doboz-t rajzol.**

Az `x` és `y` paraméterek valamint **opcionálisak**: lehagyás / `nil` érték esetén a sprite középre lesz igazítva az adott tengelyen.


## Újdonságok / Extra függvények

#### `ChangeState(s: State)`
Ezzel a fügvénnyel lehet kicserélni az aktív State-t. Automatikusan meghívja az adott State `init()` függvényét.

## Fontosabb fájlok

#### `main.lua`
Nem kell törődni vele, ide van begyömöszölve minden extra dolog amit nem kell módosítani.

#### `conf.lua`
Standard Love2D config fájl: https://love2d.org/wiki/Config_Files

#### `constants.lua`
Globális konstansok, főleg méretezéshez.

#### `background.lua`
A scalel-t ablakot körülvevő keretre rajzoló State forrása.

#### `states.lua`
Ide kell hozzáadni az új State-eket, a példákhoz hasonlóan.