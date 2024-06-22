;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mario-like game                         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
menu menubar {
  mario 
  .new map { mariolikegame -f  }
  .-
  .lots of anim { mariolikegame -f lotsofanim.obj }
  .fucking huge map (but empty) { mariolikegame -f fhugemap.obj }
  .test big map { mariolikegame -f testbigmap.obj }


}

alias f2 { mariolikegame -f  }

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: launch the game
; param:  
alias mariolikegame {

  var %file = $1

  if ($1 == -f) {
    game_Unload
    %file = $2
  }

  if (!$game_IsRunning()) {

    if (!$game_Launch(%file,22,16)) {

      game_Unload
    }
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: unload the game
; param: 
alias -l game_Unload {

  .timered off

  window -c @edc
  window -c @edb0
  window -c @edt
  window -c @edts

  if ($hget(edig)) {
    var %id = $obj_readFirst(spritesheet)
    while (%id) {
      window -c $+(@edbss,$obj_get(spritesheet,%id).name)
      %id = $obj_readNext(spritesheet)
    }
  }

  engine_ClearData
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_ClearData {

  if ($hget(edig)) hfree edig

  unset %tile.*
  unset %map.*
  unset %win.*
  unset %cam.*
  unset %buffer.*
  unset %fps.*
  unset %game.*
  unset %phys.*
  unset %keydown[*]
  unset %keypress[*]
  unset %collision.*
  unset %edit.*
  unset %player.*
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l game_IsRunning {

  return $hget(edig)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l game_Launch {

  var %w = $2
  var %h = $3

  window -hpf @edt 0 0 992 418
  window -hp @edts 0 0 600 800

  if ($engine_Init($1, %w, %h)) {

    window -Bdfkop +fnt @edc 0 0 %win.w %win.h

    ; +128 to w and h is a buffer size to fit 2 tiles max (used for scrolling)
    window -hpf @edb0 0 0 $calc(%win.w + 128) $calc(%win.h + 128)

    var %id = $obj_readFirst(spritesheet)
    while (%id) {
      game_InitSpritesSheet $obj_get(spritesheet,%id).name $obj_get(spritesheet,%id).file
      %id = $obj_readNext(spritesheet)
    }

    if ($engine_JumpToMap($obj_get(game,1).starting_map)) {

      .timered -om 0 0 engine_GameLoop 

      engine_SetFont $font.default

      return 1
    }
    else {
      engine_showError Can't find $qt($obj_get(game,1).starting_map) map
    }
  }
  else {
    return 0 
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l game_InitSpritesSheet {

  var %path = $+($scriptdir,$2-)

  if ($isfile(%path)) {

    var %w = $pic(%path).width
    var %h = $pic(%path).height

    window -hpf $+(@edbss,$1) 0 0 %w %h
    drawpic $+(@edbss,$1) 0 0 $shortfn(%path)
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_Init {

  engine_ClearData

  hmake edig 1000

  var %file = $game_Path($1)
  if ($isfile(%file)) {
    if (!$engine_LoadMap(%file)) {
      engine_ShowError Can't load map file %file
      return 0
    }
    set %game.file %file
  }
  else {
    if (!$engine_LoadObjectsFile(objects.txt)) {
      engine_ShowError Can't load objects.txt
      return 0
    } 
    unset %game.file
  } 

  obj_clear cp

  set %tile.w $obj_get(game,1).tile_w
  set %tile.h $obj_get(game,1).tile_h

  ; window size
  set %win.w $calc(%tile.w * $2)
  set %win.h $calc(%tile.h * $3)

  set %game.bx $calc(%tile.w * 9)
  set %game.bw $calc(%win.w - %game.bx - %tile.w)

  set %game.by $calc(%tile.h * 7)
  set %game.bh $calc(%win.h - %game.by)

  engine_createPlayer mario 10 300

  %game.cp.x = 10
  %game.cp.y = 300

  var %id = $obj_ReadFirst(tileset)
  if (%id) {
    drawpic -n @edt 0 0 $game_path($obj_get(tileset,%id).filename)
  }

  ; start the game by controlling the first player
  set %game.cp $obj_readFirst(cp)

  ;
  engine_SetFont $rgb(255,255,255) arial 10

  phys_InitConst 

  set %fps.val 65
  set %fps.lc $ticks
  set %fps.fc 0

  set %game.animFrame 0

  return 1
}

alias -l creep_spawn {

  var %id = $obj_getNextId(mon)

  obj_new mon %id
  obj_set mon %id x $1
  obj_set mon %id y $2
  obj_set mon %id w 32
  obj_set mon %id h 32
  obj_set mon %id maxvel 6
  obj_set mon %id jump 10
  obj_set mon %id rgb $rgb(255,0,0)
  obj_set mon %id face R
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias engine_createPlayer {

  var %pid = $obj_findByName(player,$1)

  var %id = $obj_getNextId(cp)
  obj_new cp %id
  obj_set cp %id x $2
  obj_set cp %id y $3
  obj_set cp %id maxvel $obj_get(player,%pid).velocity
  obj_set cp %id jump $obj_get(player,%pid).jump
  obj_set cp %id detectBorder $obj_get(player,%pid).detectBorder
  obj_set cp %id face R
  obj_set cp %id vx 0
  obj_set cp %id vy 0

  player_setSprite %id $obj_get(player,%pid).sprite
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_InitObjPhys {

  obj_set $1 $2 vx 0
  obj_set $1 $2 vy 0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l phys_InitConst {

  ; terminal velocity 
  set %phys.tv 9

  ; check collision or not
  set %phys.checkColl 1

  ; x&y acceleration
  set %phys.ax .18
  set %phys.ay .3

  ; x deceleration
  set %phys.dx .08
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: type, id 
; desc: 
alias -l phys_InitObj {

  obj_set $1 $2 vx 0
  obj_set $1 $2 vy 0
  obj_set $1 $2 xoff 0
  obj_set $1 $2 yoff 0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias engine_JumpToMap {

  var %mapid = $obj_findByProp(map,name,$1)
  if (%mapid) {
    set %map.id %mapid

    set %cam.x 0
    set %cam.y 0

    set %buffer.x 0
    set %buffer.y 0

    set %map.w $obj_get(map,%map.id).map_w
    set %map.h $obj_get(map,%map.id).map_h

    set %buffer.w $calc(%win.w + %tile.w * 2)
    set %buffer.h $calc(%win.h + %tile.h * 2)

    set %cam.maxw $calc(%map.w * %tile.w - %win.w)
    set %cam.maxh $calc(%map.h * %tile.h - %win.h)

    ; number of tiles that fits on screen
    set %win.xtile $calc(%win.w / %tile.w)
    set %win.ytile $calc(%win.h / %tile.h)
    drawrect -r @edc 0 1 0 400 %win.w 20
    drawtext -r @edc 0 arial 16 20 380 loading map ... %map.w tiles by %map.h tiles
    ; creates a row of tiles at bottom of the map to handle collision detection
    var %n = 0, %t = $calc(%map.w + %map.h)
    var %x = 0, %m = $obj_findByName(tile,blocker)
    while (%x < %map.w) {
      hadd edig $+(%map.id,%x,.,%map.h,.m) %m
      if ($calc(%n % 30) == 0) {
        drawrect -rf @edc 255 1 2 401 $calc((%n / %t) * %win.w - 1) 18
      }
      inc %n
      inc %x
    }
    drawrect -rf @edc 255 1 2 401 $calc((%win.w / 2) - 1) 18

    ; creates a row of tiles at both sides of the map to handle collision detection
    var %y = 0
    while (%y < %map.h) {
      if ($calc(%n % 30) == 0) {
        drawrect -rf @edc 255 1 2 401 $calc((%n / %t) * %win.w - 2) 18
      }
      inc %n
      hadd edig $+(%map.id,-1,.,%y,.m) %m
      hadd edig $+(%map.id,%map.w,.,%y,.m) %m
      inc %y
    }
    drawrect -rf @edc 255 1 $calc(%win.w / 2) 401 $calc(1 * (%win.w / 1)) 18

    buffer_Redraw

    return 1
  }
  else {
    return 0
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_GameLoop {

  %player.killFrame = 0

  if (!%game.paused) {
    %game.ticks = $calc($ticks - %game.deltaticks)
  }

  ; update animation frame number
  if ($calc(%game.ticks - %game.anim_sync) >= 100) {
    %game.af = $calc((%game.af + 1) % 4)
    %game.anim_sync = %game.ticks
  }

  engine_HandleKeypress

  if (%game.paused) {

    engine_RenderPauseScreen
  }
  else {

    engine_UpdateAndRender
  }

  engine_UpdateFps 

  drawdot @edc

  ; clear the keypresses if needed
  if (%game.clearkeypress) {
    unset %keypress[*]
    %game.clearkeypress = 0
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_renderPauseScreen {

  drawtext -nr @edc $rgb(255,255,255) arial 16 400 300 PAUSE
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_HandleKeypress {

  if (%keypress[67]) {
    %game.camera = $abs($calc(%game.camera - 1))
    engine_SetFont $rgb(255,255,255) Arial 26
    msg_Show -1 10 1500 camera is now $iif(%game.camera,centered,loose) 
    engine_SetFont $font.default
  }

  if (%keypress[66]) {
    if (%player.state != bigmario) {
      engine_SetFont $rgb(255,255,255) Arial 26
      msg_Show -1 10 2000 cheat : big mario
      engine_SetFont $font.default
      player_changeState bigmario
    }
  }

  if (%keypress[32]) {
    %game.paused = $abs($calc(%game.paused - 1))
    if (!%game.paused) {
      %game.deltaticks = $calc($ticks - %game.ticks)
    }
  }

  if (%game.paused) {
    return
  }

  if (!$obj_get(cp,%game.cp).crouch) {
    if (%keydown[37]) {
      player_WalkLeft %game.cp
    }
    elseif (%keydown[39]) {
      player_WalkRight %game.cp
    }
  }

  if (%keypress[38]) {
    player_Jump %game.cp 100
  }

  if (!%keydown[40]) {
    if ($obj_get(cp,%game.cp).crouch) {
      player_crouch %game.cp 0
    }
  }

  if (%keypress[40]) {
    player_crouch %game.cp 1
  }  

  if (%game.cp && !%game.edit) {
    if (%keypress[71]) { 
      engine_SetEditMode 1 
    }
  }
  else {

    if (%keypress[33]) {
      if ($editor_prevTile()) {
        %edit.selm = $v1
      }
      else %edit.selm = 0
    }

    if (%keypress[34]) { 
      if ($editor_nextTile()) {
        %edit.selm = $v1
      }
    }

    if (%keypress[83]) {

      var %name
      if (%game.file) %name = %game.file
      else %name = $sfile($game_Path())

      if (%name) {
        if ($engine_SaveMap(%name)) {
          engine_SetFont $rgb(255,255,255) Arial 20
          msg_Show -1 10 2000 Map saved
          engine_SetFont $font.default
        }
      }
    }

    if (%keypress[76]) { 
      var %name = $sfile($game_Path()) 
      if (%name) {
        if ($engine_LoadMap(%name)) {
          engine_setEditMode 0
        }
      }
    }

    if (%keypress[49]) {
      engine_createplayer goomba %edit.selx %edit.sely
    }

    if (%keypress[50]) {
      engine_createplayer koopa %edit.selx %edit.sely
    }

    if (%keypress[51]) {
      engine_createplayer goombafly %edit.selx %edit.sely
    }

    if (%keypress[52]) {
      engine_createplayer shell %edit.selx %edit.sely
    }

    if (%keypress[71]) { engine_SetEditMode 0 }
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l editor_prevTile {

  var %id = 0
  if (%edit.selm) {
    %id = $obj_findPrev(tile,%edit.selm)
    while (%id) {
      if ($obj_get(tile,%id).editor) {
        break
      }
      else {
        %id = $obj_findPrev(tile,%id)
      }
    }
  }

  return %id
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l editor_nextTile {

  var %id = %edit.selm
  if (%id) %id = $obj_findNext(tile,%id)
  else %id = $obj_readFirst(tile)

  while (%id) {
    if ($obj_get(tile,%id).editor) {
      break
    }
    else {
      %id = $obj_findNext(tile,%id)
    }
  }

  return %id
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_UpdateCamera {

  if (%game.cp && !%game.edit) {

    ; follow the player
    if (%game.camera == 1) {
      cam_ScrollToPlayer %game.cp
    }
    else {

      var %x = $calc($obj_get(cp,%game.cp).x - %cam.x)
      var %y = $calc($obj_get(cp,%game.cp).y - %cam.y)

      if (%x < %game.bx) {
        cam_Pan $calc(-1 * (%game.bx - %x)) 0
      }
      elseif (%x > %game.bw) {
        cam_Pan $calc(-1 * (%game.bw - %x)) 0
      }

      if (%y < %game.by) {
        cam_Pan 0 $calc(-1 * (%game.by - %y))
      }
      elseif (%y > %game.bh) {
        cam_Pan 0 $calc(-1 * (%game.bh - %y))
      }
    }
  }
  else {

    if (!%game.mousedown) {
      if (!$editor_isMouseInEditor) {
        if ($mouse.x > $calc(%win.w - 48)) {
          cam_pan 4 0
        }
        if ($mouse.x < 48) {
          cam_pan -4 0
        }
        if ($mouse.y < 48) {
          cam_pan 0 -4
        }
        if ($mouse.y > $calc(%win.h - 48)) {
          cam_pan 0 4
        }
      }
    }
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_SetEditMode {

  %game.edit = $1

  if ($1) {

    engine_SetFont $rgb(255,255,255) Arial 20
    msg_Show -1 50 2000 Entering map editor
    engine_SetFont $font.default

    ; center the selector 
    %edit.selx = $calc(%cam.x + %win.w / 2)
    %edit.sely = $calc(%cam.y + %win.h / 2)

    if (!%edit.selm) {
      %edit.selm = $editor_nextTile()
    }

    %edit.tool.w = 30
    %edit.tool.h = 2

    %edit.tool.x = 80
    %edit.tool.y = 30

    engine_createEditorTileSet

    buffer_Redraw
  }
  else {

    engine_SetFont $rgb(255,255,255) Arial 20
    msg_Show -1 50 2000 Leaving map editor
    engine_SetFont $font.default
    cam_MoveToPlayer %game.cp
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: x y duration text 
; desc: 
alias -l msg_Show {

  ; use -1 for x-y to center message
  ; use -1 for duration for unknown duration (use msg_Kill <id> to del msg)

  var %id = $obj_getNextId(msg)
  if (%id) {

    var %start = %game.ticks

    if ($3 == -1) var %end = $calc(%game.ticks + $math_HugeInt())
    else var %end = $calc(%start + $3)

    obj_new msg %id
    obj_set msg %id start %start
    obj_set msg %id end %end
    obj_set msg %id font $engine_GetFont

    var %font = %game.fontname
    var %size = %game.fontsize
    var %color = %game.fontcolor

    var %x = $1
    var %y = $2    
    var %msg = $4-

    if (%x == -1) {
      var %w = $width(%msg,%font,%size)
      %x = $calc((%win.w - %w) / 2)
    }

    if (%y == -1) {
      var %h = $height(%msg,%font,%size)
      %y = $calc((%win.h - %h) / 2)
    }

    obj_set msg %id x %x
    obj_set msg %id y %y
    obj_set msg %id msg %msg

    return %id
  }
  else {
    engine_ShowError Cannot show message > $4-
    return -1
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l msg_Kill {

}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l buffer_Redraw {

  obj_clear ab

  var %x = $calc(%buffer.x / %tile.w)
  var %w = $calc(%x + %win.xtile + 2)

  while (%x < %w) {
    buffer_RedrawCol %x
    inc %x
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l buffer_RedrawCol {

  var %y = $calc(%buffer.y / %tile.h)
  var %h = $calc(%y + %win.ytile + 2)

  while (%y < %h) {
    buffer_RedrawTile $1 %y
    inc %y
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l buffer_RedrawRow {

  var %x = $calc(%buffer.x / %tile.w)
  var %w = $calc(%x + %win.xtile + 2)

  while (%x < %w) {
    buffer_RedrawTile %x $1
    inc %x
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l buffer_RedrawTile {

  var %bufx = $calc(($1 - %buffer.x / %tile.w) * %tile.w)
  var %bufy = $calc(($2 - %buffer.y / %tile.h) * %tile.h)
  var %m = $hget(edig,$+(%map.id,$1,.,$2,.m))

  var %r = $calc($abs($cos($calc($1 / 10))) * 200)
  var %g = $calc($abs($sin($calc($2 / 10))) * 200)
  var %b = 255

  drawrect -rnf @edb0 $rgb(%r,%g,%b) 1 %bufx %bufy %tile.w %tile.h

  if (%m) {

    var %imgcache = $hget(edig,$+(%map.id,$1,.,$2,.imgcache0))
    if (%imgcache) {

      var %anim = $obj_get(tile,%m).anim
      if (%anim) {

        var %id = $obj_getnextid(ab)

        obj_new ab %id

        obj_set ab %id x $1
        obj_set ab %id y $2

        hadd edig $+(%map.id,$1,.,$2,.animid) %id
      }
      else {
        drawcopy -tn @edt $rgb(255,0,255) %imgcache @edb0 %bufx $calc(%bufy - $3) %tile.w %tile.h
      }
    }
  }

  if (%game.edit) {
    drawrect -ntr @edb0 $rgb(128,128,128) 1 %bufx %bufy $calc(%tile.w + 1) $calc(%tile.h + 1)
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_UpdateAndRender {

  engine_UpdateCamera

  drawcopy -n @edb0 $calc(%cam.x % %tile.w) $calc(%cam.y % %tile.h) %win.w %win.h @edc 0 0

  engine_renderAllAnimBlocks

  obj_ForEach cp engine_RenderPlayers
  obj_ForEach msg engine_RenderMsg

  if (%collision.bl) {
    engine_RenderBl2
  }

  if (%game.edit) {
    engine_RenderEditor
  }

  drawtext -nr @edc 16777215 arial 12 1 -2 %fps.val   (press G for map editor)
}

alias -l engine_RenderBl2 {
  var %e = $calc($ticks - %collision.t)

  var %x = %collision.blx
  var %y = %collision.bly

  var %bufx = $calc((%x - %buffer.x / %tile.w) * %tile.w)
  var %bufy = $calc((%y - %buffer.y / %tile.h) * %tile.h)

  if (%e > 200) %e = 200

  var %d = $calc($sin($calc(%e / 200 * $pi)) * 14)

  var %rx = $calc(%x * %tile.w - $floor(%cam.x))
  var %ry = $calc(%y * %tile.h - %cam.y)

  drawrect -nrf @edc 0 1 %rx %ry %tile.w %tile.h

  drawcopy -nr @edb0 %bufx %bufy %tile.w %tile.h @edc %rx $calc(%ry - %d) %tile.w %tile.h

  if (%e >= 200) {
    %collision.t = 0
    %collision.bl = 0
  }
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_renderAllAnimBlocksSlow {

  var %n = $floor($calc($obj_count(ab) / 4))
  while (%n) {
    var %id = $obj_readNext(ab)
    if (!%id) %id = $obj_readFirst(ab)
    engine_renderAnimBlocks %id
    dec %n
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_renderAllAnimBlocks {

  var %nb = $obj_count(ab)
  if (%nb > 0) {

    ; this method is only worth using if we have more than 16 animated objects
    if (%nb > 16) {

      var %n = $ceil($calc(%nb / 4))

      %game.n = $calc((%game.n + 1) % 4)
      var %n1 = $calc(%game.n * %n + 1)
      var %n2 = $calc((%game.n + 1) * %n)

      obj_ForEach ab engine_renderAnimBlocks %n1 %n2
    }
    else {

      obj_ForEach ab engine_renderAnimBlocks 
    }
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_RenderExplosions {

  var %id = $obj_ReadFirst(exp)
  while (%id) {

    var %d = $calc(%game.ticks - $obj_get(exp, %id).t)

    if (%d < 300) {

      var %x = $calc($obj_get(exp, %id).x * %tile.w + %tile.w / 2 - %cam.x)
      var %y = $calc($obj_get(exp, %id).y * %tile.h + %tile.h / 2 - %cam.y)

      drawdot -nri @edc $rgb($r(0,255),$r(0,255),$r(0,255)) $r(14,27) %x %y

    }
    else {
      obj_delete exp %id
    }

    %id = $obj_ReadNext(exp)
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_RenderAnimBlocks {

  var %x = $obj_get(ab,$1).x
  var %y = $obj_get(ab,$1).y

  drawcopy -tn @edt 16711935 $hget(edig,$+(%map.id,%x,.,%y,.imgcache,%game.af)) @edb0 $calc((%x - %buffer.x / %tile.w) * %tile.w) $calc((%y - %buffer.y / %tile.h) * %tile.h) %tile.w %tile.h
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_RenderBombs {

  var %id = $obj_ReadFirst(bomb)
  while (%id) {

    var %explode_at = $obj_get(bomb,%id).explode_at

    if (%game.ticks >= %explode_at) {
      ; do_explosion $obj_get(bomb,%id).x $obj_get(bomb,%id).y $obj_get(bomb,%id).expl_w $obj_get(bomb,%id).expl_h
      obj_delete bomb %id
    }
    else {

      var %x = $calc($obj_get(bomb,%id).x - %cam.x)
      var %y = $calc($obj_get(bomb,%id).y - %cam.y)
      var %w = $obj_get(bomb,%id).w
      var %h = $obj_get(bomb,%id).h

      var %time_left = $round($calc((%explode_at - %game.ticks) / 1000),0)

      ; Ajust vertical velocity
      var %vy = $obj_get(bomb,%id).vy + %phys.ay

      if (%vy > %phys.tv) %vy = %phys.tv
      obj_set bomb %id vy %vy

      inc %y %vy

      ; if ($phys_CheckCollisionBott(%x,%y,%w,%h,0)) {
      ;   %y = %collision.y
      ; }

      drawrect -nfr @edc $rgb(0,0,0) 1 $calc(%x - %cam.x) $calc(%y - %cam.y) %w %h
      drawtext -nr @edc $ed.getFont $calc(%x + 1) %y %time_left

      obj_set bomb %id y %y
    }
    %id = $obj_readNext(bomb)
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_RenderMsg {

  var %id = $1

  if ($obj_get(msg,%id).end > %game.ticks) {
    var %msg = $obj_get(msg,%id).msg
    if (%msg) {
      engine_SetFont $obj_get(msg,%id).font
      drawtext -nr @edc $engine_GetFont $calc($obj_get(msg,%id).x) $calc($obj_get(msg,%id).y) %msg
      engine_SetFont $font.default
    }
  }
  else {
    obj_delete msg %id
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_LoadMap {

  hload -b edig $1-

  return 1
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_SaveMap {

  hsave -b edig $1-

  return 1
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_ToggleCollision {

  %phys.checkcoll = $abs($calc(%phys.checkcoll - 1))
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias math_Rand2 {

  var %n = $r(0,$abs($calc($1 - $2)))
  if ($1 > $2) return $calc($1 - %n)
  else return $calc($1 + %n)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_RenderParticlesEffect {

  var %id = $obj_readFirst(pe)
  while (%id) {

    var %pmin = $obj_get(pe,%id).p_min
    var %pmax = $obj_get(pe,%id).p_max
    var %iter = $obj_get(pe,%id).n_iter
    var %r1 = $obj_get(pe,%id).r1, %r2 = $obj_get(pe,%id).r2
    var %g1 = $obj_get(pe,%id).g1, %g2 = $obj_get(pe,%id).g2
    var %b1 = $obj_get(pe,%id).b1, %b2 = $obj_get(pe,%id).b2

    var %rw = $obj_get(pe,%id).rw
    var %rh = $obj_get(pe,%id).rh

    var %x1 = $calc($obj_get(pe,%id).x1 - %cam.x - %rw / 2)
    var %y1 = $calc($obj_get(pe,%id).y1 - %cam.y - %rh / 2)
    var %x2 = $calc(%x1 + %rw)
    var %y2 = $calc(%y1 + %rh)

    var %n = 0
    while (%n < %iter) {

      var %x = $math_Rand2(%x1,%x2)
      var %y = $math_Rand2(%y1,%y2)

      if (%x > 0 && %y > 0 && %x < %win.w && %y < %win.h) {
        drawdot -rn @edc $rgb($r(%r1,%r2),$r(%g1,%g2),$r(%b1,%b2)) $r(%pmin,%pmax) %x %y
      }
      inc %n
    }

    if (%game.ticks >= $obj_get(pe,%id).end) {
      obj_delete pe %id
    }

    %id = $obj_readNext(pe)
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: duration x y w h n 
; desc: 
alias -l engine_CreateParticlesEffect {

  var %id = $obj_getNextId(pe)
  if (%id) {

    obj_new pe %id
    obj_set pe %id start %game.ticks
    obj_set pe %id end $calc($1 + %game.ticks)

    obj_set pe %id x1 $2
    obj_set pe %id y1 $3
    obj_set pe %id rw $4
    obj_set pe %id rh $5
    obj_set pe %id p_min 5
    obj_set pe %id p_max 5
    obj_set pe %id n_iter 1

    obj_set pe %id r1 0
    obj_set pe %id r2 0

    obj_set pe %id g1 0
    obj_set pe %id g2 0

    obj_set pe %id b1 0
    obj_set pe %id b2 0

    return %id
  }
  return 0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l player_Teleport {

  if ($obj_exists(cp,$1)) {

    obj_set cp $1 x $2
    obj_set cp $1 y $3
    obj_set cp $1 vx 0
    obj_set cp $1 vy 0
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: id
; desc: 
alias -l player_Die {

  ; echo -a $time > player die $1-
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: id, height
; desc: 
alias -l player_setHeight {

  var %h1 = $obj_get(cp,$1).h
  var %h2 = $2

  var %d = $calc(%h1 - %h2)

  obj_inc cp $1 y %d
  obj_set cp $1 h %h2
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: id % force
; desc: 
alias -l player_Jump {

  var %jump = $obj_get(cp,$1).jump

  ; player can only jump if he's on ground ...
  if ($obj_get(cp,$1).hit_bot || $3) {

    var %ratio = $abs($obj_get(cp,$1).vx) / $obj_get(cp,$1).maxvel
    if (%ratio > 1) %ratio = 1

    obj_set cp $1 vy $calc(-1 * ((%jump + %ratio * 2)  * ($2 / 100)))
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: cp 
; desc: 
alias player_crouch {
  obj_set cp $1 crouch $2
  if ($2) {
    obj_set cp $1 h 30
    obj_set cp $1 y $calc($obj_get(cp,$1).y + 28)
  }
  else {
    obj_set cp $1 h 58
    obj_set cp $1 y $calc($obj_get(cp,$1).y - 28)
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias player_WalkLeft {

  var %vx = $obj_get(cp,$1).vx

  if (%vx > 0) dec %vx $calc(%phys.ax * .6)
  else dec %vx %phys.ax

  obj_set cp $1 vx %vx
  obj_set cp $1 face l
  obj_inc cp $1 fr
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias player_WalkRight {

  var %vx = $obj_get(cp,$1).vx

  if (%vx < 0) inc %vx $calc(%phys.ax * .6)
  else inc %vx %phys.ax

  obj_set cp $1 vx %vx
  obj_set cp $1 face r
  obj_inc cp $1 fr
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_RenderEditor {

  drawrect -nr @edc $rgb(255,255,255) 2 $calc(%edit.selx - %cam.x) $calc(%edit.sely - %cam.y) %tile.w %tile.h
  drawdot -nr @edc $rgb(255,255,255) 1 $calc(%edit.selx - %cam.x + (%tile.w / 2)) $calc(%edit.sely - %cam.y + (%tile.h / 2)) 

  drawtext -nr @edc $rgb(255,255,255) arial 10 580 22 S - Save
  drawtext -nr @edc $rgb(255,255,255) arial 10 580 34 L - Load
  drawtext -nr @edc $rgb(255,255,255) arial 10 580 46 G - Exit
  drawtext -nr @edc $rgb(255,255,255) arial 10 580 58 C - Change camera mode
  drawtext -nr @edc $rgb(255,255,255) arial 10 580 70 B - Cheat big mario
  drawtext -nr @edc $rgb(255,255,255) arial 10 580 82 Right-click to bring mario back
  drawtext -nr @edc $rgb(255,255,255) arial 10 79 70 1) goomba 2) koopa 3) fly goomba 4) shell

  if (%edit.selm) {
    drawtext -nor @edc $rgb(255,255,255) arial 14 %edit.tool.x $calc(%edit.tool.y - 16) Tool : $obj_get(tile,%edit.selm).desc
  }
  else {
    drawtext -nor @edc $rgb(255,255,255) arial 14 %edit.tool.x $calc(%edit.tool.y - 16) Tool : Eraser
  }

  drawcopy -nr @edts 0 0 $calc(16 * %edit.tool.w) $calc(16 * %edit.tool.h) @edc %edit.tool.x %edit.tool.y

  ; drawscroll bar at the bottom
  var %pct = $calc(%cam.x / (%map.w * %tile.w))
  var %wid = $calc((%win.w - 20) / (%map.w * %tile.h))
  if (%wid < 0.005) %wid = 0.005
  drawrect -nrf @edc $rgb(255,255,255) 1 $calc(10 + %pct * (%win.w - 20)) $calc(%win.h - 10) $calc(%wid * %win.w)  5
  drawrect -nr @edc 0 1 10 $calc(%win.h - 10) $calc(%win.w - 20) 5

  ; drawscroll bar at the right
  var %pct = $calc(%cam.y / (%map.h * %tile.w))
  var %hei = $calc((%win.h - 20) / (%map.h * %tile.h))
  if (%hei < 0.005) %hei = 0.005

  drawrect -nrf @edc $rgb(255,255,255) 1 $calc(%win.w - 10) $calc(10 + %pct * (%win.h - 20)) 5 $calc(%hei * %win.h)
  drawrect -nr @edc 0 1 $calc(%win.w - 10) 10 5 $calc(%win.h - 20)
} 

alias -l engine_createEditorTileSet {

  drawrect -nfr @edts $rgb(196,196,196) 1 0 0 $calc(16 * %edit.tool.w) $calc(16 * %edit.tool.h)

  var %x = 0, %y = 0
  var %id = $obj_readFirst(tile)
  while (%id) {

    var %imgcache = $obj_get(tile,%id).imgcache0
    if (!%imgcache) {
      var %tm = $obj_get(tile,%id).tilemap
      %imgcache = $obj_get(tilemap,%tm).nw
      if (!%imgcache) {
        %imgcache = $obj_get(tilemap,%tm).cc
      }
    }

    if (%imgcache) {

      drawcopy -nt @edt $rgb(255,0,255) %imgcache @edts $calc(1 + %x) $calc(1 + %y) 16 16

      inc %x 16
      if (%x >= $calc(16 * %edit.tool.w)) {
        %x = 0
        inc %y 16
      }
    }

    %id = $obj_readNext(tile)
  }

  drawrect -nr @edts $rgb(0,0,0) 1 0 0 $calc(16 * %edit.tool.w) $calc(16 * %edit.tool.h)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: cp spritename
; desc: 
alias player_setSprite {

  var %id = $obj_findByname(sprite,$2)
  if (%id) {

    obj_set cp $1 w $obj_get(sprite,%id).w
    obj_set cp $1 h $obj_get(sprite,%id).h
    obj_set cp $1 sprId %id
    obj_set cp $1 ss $obj_get(sprite,%id).sheet
  }
}


alias -l engine_updateNPC {

  if ($obj_get(cp,$1).detectBorder) {

    var %id = $1
    if ($obj_get(cp,%id).vy < 0.3) {

      var %x = $obj_get(cp,%id).x
      var %y = $obj_get(cp,%id).y
      var %w = $obj_get(cp,%id).w
      var %h = $obj_get(cp,%id).h
      var %face = $obj_get(cp,%id).face

      if (%face = R) {
        var %dir = 1
      }
      else {
        var %dir = -1
      }

      if (!$phys_CheckCollisionBottom($calc(%x + %dir * 14),%y,%w,%h)) {
        player_changeDirection $1
      }
    }
  }

  if ($r(0,30) == 2) {
    if ($obj_get(cp,$1).jump) {
      player_jump $1 100
    }
  }

  if ($obj_get(cp,$1).face == r) {
    player_walkright $1
  }
  else {
    player_walkleft $1
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_RenderPlayers {

  var %id = $1

  ; if it's not the player we're controlling
  if (%id != %game.cp) {
    engine_updateNPC %ID
  }

  var %maxvel = $obj_get(cp,%id).maxvel

  var %vx = $obj_get(cp,%id).vx
  if (%vx < 0) {

    inc %vx %phys.dx
    if (%vx < $calc(-1 * %maxvel)) %vx = $v2
    if (%vx > 0) {
      %vx = 0
    }
    obj_set cp %id vx %vx
  }
  elseif (%vx > 0) {

    dec %vx %phys.dx
    if (%vx > %maxvel) %vx = $v2 
    if (%vx < 0) { 
      %vx = 0
    }
    obj_set cp %id vx %vx
  }

  var %x = $obj_get(cp,%id).x
  var %y = $obj_get(cp,%id).y
  var %w = $obj_get(cp,%id).w
  var %h = $obj_get(cp,%id).h

  var %vy = $obj_get(cp,%id).vy 

  inc %vy %phys.ay
  if (%vy > %phys.tv) %vy = %phys.tv    

  obj_set cp %id vy %vy

  inc %x %vx
  inc %y %vy 

  %game.wd = $obj_get(cp,%id).wd
  inc %game.wd $abs(%vx)
  if (%game.wd > 1024) set %game.wd 0

  obj_set cp %id wd %game.wd

  if (%phys.checkcoll) {

    phys_resetCollisionFlags

    if (%vy >= 0) {
      if ($phys_CheckCollisionBottom(%x,%y,%w,%h)) {

        %y = %collision.y
        obj_set cp %id hit_bot %collision.m
        if ($obj_get(tile,%collision.m).on_hit_top) {
          $v1 %id
        }
        if (%id == %game.cp) {
          %player.jumpBonus = 0
        }
        obj_set cp %id vy 0
      }
      else {
        obj_set cp %id hit_bot 0
      }
    }
    else {
      obj_set cp %id hit_bot 0
    }

    if (%vy < 0) {

      if ($phys_CheckCollisionTop(%x,%y,%w,%h)) {

        %y = %collision.y
        obj_set cp %id hit_top %collision.m

        var %m = $hget(edig,$+(%map.id,%dotx,.,%doty,.m))

        if ($obj_get(tile,%collision.m).on_hit_bottom) {
          $v1 %game.cp %collision.dotx %collision.doty
        }
        if (%vy < 0) {
          obj_set cp %id vy 0
        }
      }
      else {
        obj_set cp %id hit_top 0
      }
    }
    else {
      obj_set cp %id hit_top 0
    }

    if (%vx < 0) {
      if ($phys_CheckCollisionLeft(%x,%y,%w,%h)) {

        %x = %collision.x

        if (%id != %game.cp) {
          player_changeDirection %id
        }

        obj_set cp %id hit_left %collision.m
        if ($obj_get(tile,%collision.m).on_hit_right) {
          $v1 %game.cp
        }
        if (%vx < 0) {
          obj_set cp %id vx 0
        }
      }
      else {
        obj_set cp %id hit_left 0
      }
    }
    else {
      obj_set cp %id hit_left 0
    }

    if (%vx > 0) {
      if ($phys_CheckCollisionRight(%x,%y,%w,%h)) {

        %x = %collision.x

        if (%id != %game.cp) {
          player_changeDirection %id
        }

        obj_set cp %id hit_right %collision.m       
        if ($obj_get(tile,%collision.m).on_hit_left) {
          $v1 %game.cp 
        }
        if (%vx > 0) {
          obj_set cp %id vx 0
        }
      }
      else {
        obj_set cp %id hit_right 0
      }  
    }
    else {
      obj_set cp %id hit_right 0
    }  
  }

  var %fr = $int($calc(($obj_get(cp,%id).wd / 25) % 2))

  var %face = $obj_get(cp, %id).face
  var %key

  if ((%face == r && %vx < 0) || (%face == l && %vx > 0) ) {
    var %key = BR
  }
  else if (%vx == 0) {
    var %key = SS
  }
  else {
    if ($abs(%vx) >= 7) {
      var %key = $+(R,%fr)
    }
    else {
      var %key = $+(W,%fr)
    }
  }

  if (%vy < 0) {
    if ($abs(%vx) >= 7) {
      var %key = RJ
    }
    else {
      var %key = WJ
    }
  }

  if ($obj_get(cp,%id).crouch) {
    var %key = CR
  }

  var %sprId = $obj_get(cp,%id).sprid
  var %c = $obj_getProp(sprite,%sprId,%key)
  var %ss = $obj_get(cp,%id).ss

  if (%c) {
    if (%face == r) {
      drawcopy -nt $+(@edbss,%ss) $rgb(255,0,255) %c @edc $calc(%x - %cam.x) $calc(%y - %cam.y) %w %h
    }
    else {
      drawcopy -nt $+(@edbss,%ss) $rgb(255,0,255) %c @edc $calc(%x - %cam.x + %w) $calc(%y - %cam.y) $calc(0 - %w) %h
    }
  }

  obj_set cp %id x %x
  obj_set cp %id y %y

  if (%id != %game.cp) {
    if (!%player.KillFrame) {
      var %dist = $hypot($calc(%game.cp.x - %x), $calc(%game.cp.y - %y))
      if (%dist < 40) {
        if (%game.cp.vy > 0.3) {
          inc %player.jumpBonus 5
          %player.killFrame = 1
          player_jump %game.cp $calc(100 + %player.jumpBonus) 1
          obj_delete cp %id
        }
        else {
          if (!$timer(cs)) {
            if (%player.state == minimario) {
              drawtext -nr @edc 255 arial 50 50 50 too bad, you're dead
            }
            else {
              player_ChangeState minimario
            }
          }
        }
      }
    }
  }
  else {
    %game.cp.x = %x  
    %game.cp.y = %y
    %game.cp.vy = %vy
  }
}

alias player_changeDirection {

  if ($obj_get(cp,$1).face == R) {

    player_WalkLeft $1
  }
  else {
    player_WalkRight $1

  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias player_ChangeState {

  if (%player.state != $1) {
    .timerCS -m 11 90 player_doChangeState %player.state $1
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias player_doChangeState {

  dec %player.changestate
  if (%player.state == $2) {
    player_setSprite %game.cp $1
    %player.state = $1
  }
  else {
    player_setSprite %game.cp $2
    %player.state = $2
  }

  if (%player.state == minimario) {
    obj_inc cp %game.cp y 24
  }
  else {
    obj_dec cp %game.cp y 24
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l phys_resetCollisionFlags {

  %collision.m = 0
  %collision.x = 0
  %collision.y = 0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l phys_CheckCollisionTop {
  ; var %dotx = $floor($calc(($1 + $3 - 7) / %tile.w))

  var %cx = $calc($1 + $3 / 2)
  var %dotx = $floor($calc(%cx / %tile.w))
  var %doty = $floor($calc($2 / %tile.h))

  var %m = $hget(edig,$+(%map.id,%dotx,.,%doty,.m))

  if (!%m) {
    var %dotx = $floor($calc((%cx + 7) / %tile.w))
    var %m = $hget(edig,$+(%map.id,%dotx,.,%doty,.m))
  }

  if (!%m) {
    var %dotx = $floor($calc((%cx - 7) / %tile.w))
    var %m = $hget(edig,$+(%map.id,%dotx,.,%doty,.m))
  }

  if (%m) {
    if (b isin $obj_get(tile,%m).collision) {
      %collision.dotx = %dotx
      %collision.doty = %doty
      %collision.y = $calc(%doty * %tile.h + %tile.h + 1)
      %collision.m = %m

      return 1  
    }
    else {
      if ($obj_get(tile,%m).on_touch) {
        $v1 %game.cp %dotx %doty
      }
    }
  }

  return 0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l phys_CheckCollisionLeft {

  var %dotx = $floor($calc($1 / %tile.w))
  var %doty1 = $floor($calc(($2 + 7) / %tile.h))
  var %m = $hget(edig,$+(%map.id,%dotx,.,%doty1,.m))

  if (!%m) {
    var %doty2 = $floor($calc(($2 + $4 - 7) / %tile.h)) 
    %m = $hget(edig,$+(%map.id,%dotx,.,%doty2,.m)) 
  }

  if (%m) {

    if (r isin $obj_get(tile,%m).collision) {

      %collision.x = $calc(%dotx * %tile.w + %tile.w - $5)
      %collision.m = %m

      return 1
    }
    else {
      if ($obj_get(tile,%m).on_touch) {
        $v1 %game.cp %dotx %doty
      }
    }
  }
  return 0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l phys_CheckCollisionRight {

  var %dotx = $floor($calc(($1 + $3) / %tile.w))
  var %doty1 = $floor($calc(($2 + 7) / %tile.h))
  var %m = $hget(edig,$+(%map.id,%dotx,.,%doty1,.m))

  if (!%m) {
    var %doty2 = $floor($calc(($2 + $4 - 7) / %tile.h)) 
    %m = $hget(edig,$+(%map.id,%dotx,.,%doty2,.m))
  }

  if (%m) {

    if (l isin $obj_get(tile,%m).collision) {

      %collision.x = $calc(%dotx * %tile.w - $3 + $5)
      %collision.m = %m

      return 1
    }
    else {
      if ($obj_get(tile,%m).on_touch) {
        $v1 %game.cp %dotx %doty
      }
    }
  }

  return 0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: x y w h 
; desc: 
alias -l phys_CheckCollisionBottom {

  var %cx = $calc($1 + $3 / 2)
  ; var %dotx = $floor($calc(($1 + $3 - 10) / %tile.w))
  var %dotx = $floor($calc(%cx / %tile.w))
  var %doty = $floor($calc(($2 + $4) / %tile.h))

  var %m = $hget(edig,$+(%map.id,%dotx,.,%doty,.m))

  if (!%m) {
    var %dotx = $floor($calc((%cx + 7) / %tile.w))
    var %m = $hget(edig,$+(%map.id,%dotx,.,%doty,.m))
  }

  if (!%m) {
    var %dotx = $floor($calc((%cx - 7) / %tile.w))
    var %m = $hget(edig,$+(%map.id,%dotx,.,%doty,.m))
  }

  if (%m) {
    var %collision = $obj_get(tile,%m).collision
    if (t isin %collision) {
      if (%collision == t) {
        var %doty2 = $floor($calc(($2 + $4) / %tile.h - 1))
        var %m2 = $hget(edig,$+(%map.id,%dotx,.,%doty2,.m))
        if ((%m2) && (%m2 == %m)) {
          return 0
        }
      }

      if ($calc($2 + $4) >= $calc(%doty * %tile.h)) {

        %collision.y = $calc(%doty * %tile.h - $4)
        %collision.m = %m

        return 1
      }
    }
    else {

      if ($obj_get(tile,%m).on_touch) {
        $v1 %game.cp %dotx %doty
      }
    }
  }

  return 0
}

alias -l bounce_block {

  %collision.bl = 1
  %collision.t = $ticks
  %collision.blx = %collision.dotx
  %collision.bly = %collision.doty
}

alias -l collect_coin {

  map_destroyTile $2 $3
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: x, y, m
; desc: 
alias -l map_setTile {

  var %oldm = $hget(edig,$+(%map.id,$1,.,$2,.m))
  var %m = $3

  map_destroyTile $1 $2

  hadd edig $+(%map.id,$1,.,$2,.m) %m

  if ((!%m) && (%oldm)) {

    var %tilemap = $obj_get(tile,%oldm).tilemap
    if (%tilemap) {
      var %x = -1
      while (%x < 2) {
        var %y = -1
        while (%y < 2) {
          if ((%x) || (%y)) {
            var %tx = $calc($1 + %x), %ty = $calc($2 + %y)
            if ($hget(edig,$+(%map.id,%tx,.,%ty,.m)) == %oldm) {
              var %imgcache = $tilemap_findImgCache(%tilemap,%tx,%ty)
              if (%imgcache) {
                hadd edig $+(%map.id,%tx,.,%ty,.imgcache0) %imgcache
                buffer_RedrawTile %tx %ty
              }
            }
          }
          inc %y
        }
        inc %x
      }
    }
  }

  var %tilemap = $obj_get(tile,%m).tilemap
  if (%tilemap) {

    var %imgcache = $tilemap_findImgCache(%tilemap,$1,$2)

    hadd edig $+(%map.id,$1,.,$2,.imgcache0) %imgcache
    var %x = -1
    while (%x < 2) {
      var %y = -1
      while (%y < 2) {
        if ((%x) || (%y)) {
          var %tx = $calc($1 + %x), %ty = $calc($2 + %y)
          if ($hget(edig,$+(%map.id,%tx,.,%ty,.m)) == %m) {
            var %imgcache = $tilemap_findImgCache(%tilemap,%tx,%ty)
            if (%imgcache) {
              hadd edig $+(%map.id,%tx,.,%ty,.imgcache0) %imgcache

              var %anim = $obj_get(tile,%m).anim
              if (%anim) {

                hadd edig $+(%map.id,%tx,.,%ty,.imgcache0) $obj_get(anim,%anim).k0
                hadd edig $+(%map.id,%tx,.,%ty,.imgcache1) $obj_get(anim,%anim).k1
                hadd edig $+(%map.id,%tx,.,%ty,.imgcache2) $obj_get(anim,%anim).k2
                hadd edig $+(%map.id,%tx,.,%ty,.imgcache3) $obj_get(anim,%anim).k3
              }

              buffer_RedrawTile %tx %ty
            }
          }
        }
        inc %y
      }
      inc %x
    }
  }
  else {

    var %imgcache = $obj_get(tile,%m).imgcache0
    hadd edig $+(%map.id,$1,.,$2,.imgcache0) %imgcache
    var %tx = $1
    var %ty = $2
    var %anim = $obj_get(tile,%m).anim
    if (%anim) {
      hadd edig $+(%map.id,%tx,.,%ty,.imgcache0) $obj_get(anim,%anim).k0
      hadd edig $+(%map.id,%tx,.,%ty,.imgcache1) $obj_get(anim,%anim).k1
      hadd edig $+(%map.id,%tx,.,%ty,.imgcache2) $obj_get(anim,%anim).k2
      hadd edig $+(%map.id,%tx,.,%ty,.imgcache3) $obj_get(anim,%anim).k3
    }
    else {
      hdel edig $+(%map.id,%tx,.,%ty,.imgcache1)
      hdel edig $+(%map.id,%tx,.,%ty,.imgcache2)
      hdel edig $+(%map.id,%tx,.,%ty,.imgcache3)
    }
  }

  buffer_RedrawTile $1 $2
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: detects which tile to use 
alias -l tilemap_findImgCache {

  var %tilemap = $1
  var %m = $hget(edig,$+(%map.id,$2,.,$3,.m))
  var %x = 0, %y = 0

  var %sum = 0
  var %i = -1
  while (%i < 2) {
    if ($hget(edig,$+(%map.id,$calc($2 + %i),.,$3,.m)) == %m) {
      dec %x %i 
      inc %sum $abs(%i)
    }
    inc %i
  }

  var %i = -1, %ym = 0
  while (%i < 2) {
    if ($hget(edig,$+(%map.id,$2,.,$calc($3 + %i),.m)) == %m) {
      dec %y %i
      inc %sum $abs(%i)
    }
    inc %i
  }

  var %a = $mid(ncs,$calc(%y + 2),1)
  var %b = $mid(wce,$calc(%x + 2),1)
  var %tmpa = %a, %tmpb = %b
  if (!%sum) {
    %tmpa = x
    %tmpb = x
  }

  var %ret = $obj_getProp(tilemap,%tilemap,$+(%tmpa,%tmpb))
  if ($numtok(%ret,32) != 4) {
    %ret = $obj_getProp(tilemap,%tilemap,$+(%a,%b))
    if ($numtok(%ret,32) != 4) {
      return 0
    }
  }

  return %ret
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: x, y 
; desc: 
alias -l map_destroyTile {

  var %m = $hget(edig,$+(%map.id,$1,.,$2,.m))
  if (%m) {

    if ($obj_get(tile,%m).on_destroy) {
      $v1 %m $1 $2
    }

    var %animId = $hget(edig,$+(%map.id,$1,.,$2,.animid))
    if (%animId) {
      obj_delete ab %animId
    }

    hdel -w edig $+(%map.id,$1,.,$2,.*)

    buffer_RedrawTile $1 $2
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: delay, command
; desc: 
alias -l engine_delayCmd {

  .timer -m 1 $1 $2-
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_updateFps {

  inc %fps.fc
  if ($calc($ticks - %fps.lc) >= 1000) {

    %fps.val = $calc(%fps.fc)
    %fps.lc = $ticks
    %fps.fc = 0
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
on *:keyup:@edc:*:{

  var %key = $keyval2

  set $+(%,keydown[,%key,]) 0
  set $+(%,keypress[,%key,]) 0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
on *:keydown:@edc:*:{

  var %key = $keyval2

  set $+(%,keydown[,%key,]) 1

  if ($keyrpt) {
    set $+(%,keypress[,%key,]) 0
  }
  else {
    set $+(%,keypress[,%key,]) 1
    %game.clearkeypress = 1
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
on *:close:@edc:{

  game_Unload
}

menu @edc {

  mouse {

    if (%game.edit) {
      %edit.selx = $calc(%cam.x + $mouse.x - 16)
      %edit.sely = $calc(%cam.y + $mouse.y - 16)

      if ($mouse.key & 1) {

        %game.mousedown = 1

        if (!$editor_isMouseInEditor) {

          var %tx = $int($calc((%edit.selx + %tile.w / 2) / %tile.w)) 
          var %ty = $int($calc((%edit.sely + %tile.h / 2) / %tile.h))

          if (%edit.lastkey != $+(%tx,.,%ty,.,%edit.selm)) {
            map_SetTile %tx %ty %edit.selm
            %edit.lastkey = $+(%tx,.,%ty,.,%edit.selm)
          }
        }
      }
      else {
        %game.mousedown = 0
      }
    }
  }

  rclick {
    if (%game.edit) {
      player_Teleport %game.cp %edit.selx %edit.sely
    }
  }

  sclick {
    if (%game.edit) {

      %edit.selx = $calc(%cam.x + $mouse.x - 16)
      %edit.sely = $calc(%cam.y + $mouse.y - 16)

      if ($editor_isMouseInEditor) {
        %edit.selm = $editor_getTileFromMouse
      }
      else {
        var %tx = $int($calc((%edit.selx + %tile.w / 2) / %tile.w)) 
        var %ty = $int($calc((%edit.sely + %tile.h / 2) / %tile.h))

        if (%edit.lastkey != $+(%tx,.,%ty,.,%edit.selm)) {
          map_SetTile %tx %ty %edit.selm
          %edit.lastkey = $+(%tx,.,%ty,.,%edit.selm)
        }
      }
    }
  }
}

alias -l editor_isMouseInEditor {

  return $inrect($mouse.x,$mouse.y,%edit.tool.x,%edit.tool.y,$calc(16 * %edit.tool.w),$calc(16 * %edit.tool.h))
}

alias -l editor_getTileFromMouse {

  var %x = $int($calc(($mouse.x - %edit.tool.x) / 16))
  var %y = $int($calc(($mouse.y - %edit.tool.y) / 16))

  var %n = $calc(%y * %edit.tool.w + %x + 1)
  var %c = 0

  ; TODO: this is really stupid, work something better
  var %id = $obj_readfirst(tile)
  while (%id) {
    if (%n == %c) {
      return %id
      break
    }
    inc %c

    %id = $obj_readnext(tile)
  }

  return 0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l engine_LoadObjectsFile {

  var %map = $1

  var %path = $game_Path($1)
  var %in = 0
  var %name, %type, %n, %id
  var %ok

  %ok = $isfile(%path)
  if (%ok) {

    obj_clear

    var %size = $file(%path).size

    if ($fopen(obj)) .fclose obj

    .fopen obj %path

    ; read the whole file
    while (!$feof(obj) && %ok) {

      var %line = $fread(obj)

      if ($numtok(%line,32) > 0) {
        tokenize 32 %line

        ; don't consider comments line (starts with ;)
        if ($mid($1,1,1) != $chr(59)) {

          if (%in) {

            ; check for end brackets "}"
            if ($1 == $chr(125)) { 
              if (%type == event) {
                ; set the number of lines that the event contains
                obj_set %type %id count %n
              }
              %in = 0
            }             
            else {
              if (%type == event) {
                ; replace Tabs by spaces
                var %text = $replace($1-,$chr(9),$chr(32))
                if ($len($remove(%text,$chr(32))) > 0) {
                  obj_set %type %id %n %text
                  inc %n
                }
              }
              else {
                ; get all the text after the "="
                obj_set %type %id $1 $($gettok($3-,1,59),2)
              }
            }
          }
          else {

            %type = $1
            %name = $2
            %id = $calc($obj_count(%type) + 1)

            %n = 1

            ; filter objects type, to be sure that its valid 
            var %valid_objects = :cp:game:map:tool:sprite:spritesheet:event:item:tile:tileset:tilemap:anim:shortcut:player:
            if ($pos(%valid_objects,$+(:,%type,:)) > 0) {

              %in = 1

              obj_new %type %id
              obj_set %type %id name %name 

              if (%type == tile) {
                obj_set %type %id collision tblr
                obj_set %type %id canbreak 1
                obj_set %type %id editor 1
              }

              if ($3 == : && $4 == use) {

                ; copy $5 properties in %id
                obj_copyProperties %type %id $5
              }
            }
            else {
              engine_ShowError Invalid object's type : %type
              %ok = 0
            }
          }
        }
      }
    }
    .fclose obj
  }

  ; init tilemap objects
  var %id = $obj_readFirst(tilemap)
  while (%id) {
    obj_set tilemap %id xx $engine_parseTileCache($obj_get(tilemap,%id).xx)
    obj_set tilemap %id nw $engine_parseTileCache($obj_get(tilemap,%id).nw)
    obj_set tilemap %id nc $engine_parseTileCache($obj_get(tilemap,%id).nc)
    obj_set tilemap %id ne $engine_parseTileCache($obj_get(tilemap,%id).ne)
    obj_set tilemap %id cw $engine_parseTileCache($obj_get(tilemap,%id).cw)
    obj_set tilemap %id cc $engine_parseTileCache($obj_get(tilemap,%id).cc)
    obj_set tilemap %id ce $engine_parseTileCache($obj_get(tilemap,%id).ce)
    obj_set tilemap %id sw $engine_parseTileCache($obj_get(tilemap,%id).sw)
    obj_set tilemap %id sc $engine_parseTileCache($obj_get(tilemap,%id).sc)
    obj_set tilemap %id se $engine_parseTileCache($obj_get(tilemap,%id).se)

    %id = $obj_readNext(tilemap)
  }

  ; init anim objects
  var %id = $obj_readFirst(anim)
  while (%id) {
    obj_set anim %id k0 $engine_parseTileCache($obj_get(anim,%id).k0)
    obj_set anim %id k1 $engine_parseTileCache($obj_get(anim,%id).k1)
    obj_set anim %id k2 $engine_parseTileCache($obj_get(anim,%id).k2)
    obj_set anim %id k3 $engine_parseTileCache($obj_get(anim,%id).k3)
    %id = $obj_readNext(anim)
  }

  ; initialise tiles graphic
  var %id = $obj_readFirst(tile)
  while (%id) {

    var %tile = $obj_get(tile,%id).tile
    if (%tile) {
      obj_set tile %id imgcache0 $engine_parseTileCache(%tile)
    }

    var %tilemap = $obj_get(tile,%id).tilemap
    if (%tilemap) {
      obj_set tile %id tilemap $obj_findByName(tilemap,%tilemap)
    }

    var %anim = $obj_get(tile,%id).anim
    if (%anim) {
      obj_set tile %id anim $obj_findByName(anim,%anim)
    }

    %id = $obj_readNext(tile)
  }

  return %ok
}

alias engine_parseTileCache {

  var %temp = $1

  var %tilemap = $obj_findByName(tileset,$gettok(%temp,1,46))
  var %other = $remove($gettok(%temp,2,46),tile,$chr(40),$chr(41))

  var %w = $obj_get(tileset,%tilemap).tiles_width
  var %h = $obj_get(tileset,%tilemap).tiles_height

  var %x = $calc($gettok(%other,1,44) * %w)
  var %y = $calc($gettok(%other,2,44) * %h)

  return %x %y %w %h
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias engine_ShowError {

  echo -a $1-
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: trigger_name
; desc: trigger an event using user defined event in the map definition
alias -l parser_triggerEvent {

  ; find the user defined event name
  var %name = $($+($,obj_get(map,$td.map).,$1),2)
  var %ret = 1
  if (%name) %ret = $parser_runEvent(%name,$2-)
  return %ret
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: event_id
; desc: run an user defined event
alias -l parser_runEvent {

  var %name = $1
  var %retval = 1

  if ($parser_Init(%name)) {

    var %i = 1, %comm
    var %n = $obj_get(event, %name).count

    tokenize 32 $2-

    while (%i <= %n) {

      %comm = $hget(edig,$+(@event.,%name,.,%i))
      if ($len(%comm) > 0) {

        ; do we have to execute this command?
        if ($parser_evalExec(%comm,$1-)) {

          if (%comm == return) {
            ; break the execution of the script
            %i = %n
            %retval = $gettok(%comm,2,32)
          }
          else {
            $(%comm,2)
          }
        }
      }

      inc %i
    }

    parser_Unload
  }

  return %retval
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l parser_Init {

  set %parser.skip 0
  set %parser.lvl 0
  set %parser.slv 0
  return 1
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l parser_Unload {

  unset %parser.*
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: command, parameters
; desc: check if a command line has to be executed
alias -l parser_evalExec {

  var %comm = $1
  var %f = $gettok(%comm,1,32)
  var %r = 0
  var %lvl = %parser.lvl
  var %slv = %parser.slv
  var %skip = %parser.skip

  tokenize 32 $2-

  if (%f == if) {

    inc %lvl

    if (!%skip) {
      if (!$parser_evalCondition(%comm, $1-)) {
        inc %skip
        %slv = %lvl
      }
    }
  }
  elseif (%f == else) {
    if (%skip > 0) {
      if (%lvl <= %slv) {
        dec %skip
      }
    }
    else {
      inc %skip 
    }
  }
  elseif (%f == endif) {
    if (%lvl <= %slv) {
      if (%skip > 0) {
        dec %skip
      }
    }
    dec %lvl
  }
  else {
    if (%skip == 0) {
      %r = 1
    }
  }

  %parser.skip = %skip
  %parser.lvl = %lvl
  %parser.slv = %slv

  return %r
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: crappy expression evaluator
; param:  
alias -l parser_evalCondition {

  var %cond = $1
  tokenize 32 $2-
  var %a = $remove(%cond,if $chr(40), $chr(41) then)
  var %a = $replace(%a,$chr(40),$+($chr(40),$chr(32)),$chr(41),$+($chr(32),$chr(41)))
  var %r = $ $+ iif( %a ,1,0)
  return $eval(%r,2)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: event_name
; desc: run an event, used to call events in maps event 
alias -l parser_callEvent {

  parser_runEvent $1-
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: type, dest, src 
; desc: 
alias -l obj_copyProperties {

  ; copy src object's properties into destination
  var %type = $1
  var %dest = $2
  var %src = $3

  var %wild = $+(@,%type,.,%src,.*)
  var %i = 1, %t = $hfind(edig,%wild,0,w)
  while (%i <= %t) {

    var %key = $hfind(edig,%wild,%i,w)
    var %val = $hget(edig,%key)
    obj_set %type %dest $gettok(%key,3,46) %val
    inc %i 
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: return a random object id 
; param:
alias -l obj_RandomId {

  return $r(1,$calc(2 ^ 32))
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: type 
alias -l obj_GetNextId {

  var %id = $calc($hget(edig,$+(@,$1,.nextid)) + 1)
  hinc edig $+(@,$1,.nextid)
  return %id
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: type
alias obj_Clear {

  if ($1) {
    hdel -w edig $+(@,$1,.*)
  }
  else {
    hdel -w edig $+(@,*)
    hdel -w edig $+(%map.id,*)
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: type, name
; desc: create a new object
alias -l obj_New {

  hadd edig $+(@,$1,.,$2,.ex) 1
  hadd edig $+(@,$1,.e) $hget(edig,$+(@,$1,.e)) $2
  hinc edig $+(@,$1,.count)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: type, id
; desc:
alias obj_Delete {

  if ($hget(edig,$+(@,$1,.,$2,.ex))) {

    hadd edig $+(@,$1,.e) $remtok($hget(edig,$+(@,$1,.e)),$2,1,32)

    ; fix cursor for obj_readNext()
    hdec edig $+(@,$1,.n) 

    ; flush the old object data
    hdel -w edig $+(@,$1,.,$2,.*)

    hdec edig $+(@,$1,.count) 1  
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: return the first id of the specified object type
; param: obj_type
alias obj_ReadFirst {

  hadd edig $+(@,$1,.n) 2
  return $gettok($hget(edig,$+(@,$1,.e)),1,32)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: obj_type
; desc: 
alias -l obj_ForEach {

  var %cmd = $2

  if ($3) {
    tokenize 32 $gettok($hget(edig,$+(@,$1,.e)), $+($3,-,$4), 32)
  }
  else {
    tokenize 32 $hget(edig,$+(@,$1,.e))
  }

  %cmd $*
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: return the next id of the specified object type (after reading with $obj_readFirst())
; param: obj_type
alias -l obj_ReadNext {

  var %next = $hget(edig,$+(@,$1,.n))
  hinc edig $+(@,$1,.n)
  return $gettok($hget(edig,$+(@,$1,.e)),%next,32)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: return the last id of the specified object type
; param: obj_type
alias obj_ReadLast {
  var %count = $obj_count($1)
  hadd edig $+(@,$1,.p) $calc(%count - 1)
  return $gettok($hget(edig,$+(@,$1,.e)),-1,32)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: return the previous id of the specified object type (after reading with obj_readLast)
; param: obj_type
alias obj_ReadPrev {
  var %prev = $hget(edig,$+(@,$1,.p))
  if (%prev > 0) {
    hdec edig $+(@,$1,.p)
    return $gettok($hget(edig,$+(@,$1,.e)),%prev,32)
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: type
alias obj_Count {
  return $calc($hget(edig,$+(@,$1,.count)))
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: type, id
alias obj_get {
  return $hget(edig,$+(@,$1,.,$2,.,$prop))
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: type, id
alias obj_getProp {
  return $hget(edig,$+(@,$1,.,$2,.,$3))
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: type, id, value
alias obj_set {
  hadd edig $+(@,$1,.,$2,.,$3) $4-
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: type, id
alias obj_exists {
  return $hget(edig,$+(@,$1,.,$2,.ex))
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: type, id, value
alias obj_inc {
  hinc edig $+(@,$1,.,$2,.,$3) $4
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: 
alias obj_dec {
  hdec edig $+(@,$1,.,$2,.,$3) $4
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: type, id
; desc: find the previous object of a specified object
alias obj_findPrev { 

  var %id = $obj_readFirst($1)
  var %prev = 0
  while ((%id != $2) || (!%id)) {
    %prev = %id
    %id = $obj_readNext($1)
  }
  return %prev
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: type, id
; desc: find the next object of a specified object
alias obj_FindNext {

  var %id = $obj_readFirst($1)
  while ((%id != $2) || (!%id)) %id = $obj_readNext($1)
  return $obj_readNext($1)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias obj_FindByName {

  var %id = $obj_readFirst($1)
  while ((%id) && ($obj_get($1,%id).name != $2)) {
    %id = $obj_readNext($1)
  }

  return %id
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: type, prop, value 
; desc: find an object id 
alias -l obj_FindByProp {

  var %id = $obj_readFirst($1)
  while ($hget(edig,$+(@,$1,.,%id,.,$2)) != $3) %id = $obj_readNext($1)
  return %id
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: old keyval behavior (prior to mIRC 7.15 I think)
alias -l keyval2 {

  return $asc($upper($chr($keyval)))
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l font.default { return $rgb(255,255,255) arial 10 }

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: 
alias -l engine_GetFont { 

  return %game.fontcolor %game.fontname %game.fontsize 
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: 
alias -l engine_SetFont { 

  set %game.fontcolor $1
  set %game.fontname $2 
  set %game.fontsize $3
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: 
alias -l game_Path {
  var %fn = $shortfn($+($scriptdir,$1))
  if (!$isfile(%fn)) return $qt(%fn)
  return %fn
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: 
alias -l math_HugeInt { 

  return $calc(2 ^ 64)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l cam_MoveTo {

  %cam.x = $engine_Clip($1,0,%cam.maxw)
  %cam.y = $engine_Clip($2,0,%cam.maxh)

  while ($calc(%cam.x - %buffer.x) >= %tile.w) inc %buffer.x %tile.w
  while (%cam.x < %buffer.x) dec %buffer.x %tile.w 
  while ($calc(%cam.y - %buffer.y) >= %tile.h) inc %buffer.y %tile.h
  while (%cam.y < %buffer.y) dec %buffer.y %tile.h 

  buffer_Redraw
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: 
alias -l cam_MoveToPlayer {

  cam_MoveTo $calc($obj_get(cp,$1).x - %win.w / 2) $calc($obj_get(cp,$1).y - %win.h / 2)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: x y 
alias cam_Pan {
  cam_ScrollTo $calc(%cam.x + $1) $calc(%cam.y + $2)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: 
alias -l cam_ScrollToPlayer {
  cam_ScrollTo $calc($obj_get(cp,$1).x - %win.w / 2) $calc($obj_get(cp,$1).y - %win.h / 2)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: 
; desc: 
alias -l cam_ScrollTo {

  var %clear = 0

  %cam.x = $engine_Clip($1,0,%cam.maxw)
  %cam.y = $engine_Clip($2,0,%cam.maxh)

  while ($calc(%cam.x - %buffer.x) >= %tile.w) {
    inc %buffer.x %tile.w
    drawscroll -n @edb0 $calc(%tile.w * -1 0) 0 0 0 %buffer.w %buffer.h
    buffer_RedrawCol $calc(%buffer.x / %tile.w + %win.xtile + 1)
    %clear = 1
  }

  while (%cam.x < %buffer.x) {
    dec %buffer.x %tile.w
    drawscroll -n @edb0 %tile.w 0 0 0 %buffer.w %buffer.h
    buffer_RedrawCol $calc(%buffer.x / %tile.w)
    %clear = 1
  }

  while ($calc(%cam.y - %buffer.y) >= %tile.h) {
    inc %buffer.y %tile.h
    drawscroll -n @edb0 0 $calc(%tile.h * -1) 0 0 %buffer.w %buffer.h
    buffer_RedrawRow $calc(%buffer.y / %tile.h + %win.ytile + 1)
    %clear = 1
  }

  while (%cam.y < %buffer.y) {
    dec %buffer.y %tile.h
    drawscroll -n @edb0 0 %tile.h 0 0 %buffer.w %buffer.h
    buffer_RedrawRow $calc(%buffer.y / %tile.h)
    %clear = 1
  }

  if (%clear) {

    engine_clearOffScreenAnimBlocks
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: 
alias -l engine_clearOffScreenAnimBlocks {

  obj_ForEach ab engine_ClearOffScreenAnimBlocksInt
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desc: 
; param: 
alias -l engine_ClearOffScreenAnimBlocksInt {

  var %id = $1
  var %x = $obj_get(ab,%id).x * %tile.w
  var %y = $obj_get(ab,%id).y * %tile.h

  if (!$inrect(%x,%y,$calc(%cam.x - 36),$calc(%cam.y - 36),$calc(%win.w + 72),$calc(%win.h + 72))) {

    obj_delete ab %id
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: value, min, max 
; desc: 
alias engine_Clip {

  if ($1 < $2) { return $2 }
  elseif ($1 > $3) { return $3 }
  return $1
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: cp, dotx, doty
; desc: 
alias game_breakBrick {

  game_doTileExplosionAt $2 $3
  map_destroyTile $2 $3
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; param: dotx, doty
; desc: 
alias game_doTileExplosionAt {

  var %m = $hget(edig,$+(%map.id,$1,.,$2,.m))
  if (%m) {

    var %id = $obj_getNextId(exp)

    obj_new exp %id
    obj_set exp %id x $1
    obj_set exp %id y $2
    obj_set exp %id m %m
    obj_set exp %id t %game.ticks
  }
}
