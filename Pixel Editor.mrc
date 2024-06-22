/*
Pixel Editor for mIRC v7.61+

Version:  1.1
Coded by: Dazuz @ QuakeNet


1.1
- Set a hard limit of 256 for width and height.
- Updated autosave format to reflect the change above.
- Resize now automatically adjusts the block size.
- Import can now handle multiple consecutive empty spaces properly.
- Fixed "Add..." menu hotkey suggestions.
- Couple of small fixes/improvements.

1.0
- Initial release.
*/

;This alias creates $scriptdirCube.ico file. Feel free to remove the alias, it won't break anything important.
alias pe.createicon {
  set -l %icon $qt($scriptdirCube.ico)
  if (!$isfile(%icon)) {
    bset -t & 1 Y2BgBEIBAQYgUGDIYGFgEAOyNIBYACzCAJQFkQwMDiwMGOD///+MtMBrt+9oRMak6steN+U/MiZkDrq+zMPL/6c/PPSfGHOw6YNhdP3I5sD0Y9NHSD8II+vHpnco63/x8+v/vS/uwjGx+kH6YBhZPzZzkPXPO7sHRS8u/SDce2wTin6YGejm4NKHrheXOaTow2UOqfpIxaASgBIMAA==
    if ($decode(&,bm)) && ($decompress(&,bm1)) && ($sha1(&,1) == ae378536e1f7af22066cb722dd04739a5a7fe8a4) bwrite %icon 0 &
  }
}

on *:load: {
  if ($version < 7.61) {
    echo $color(info) -at * Unsupported mIRC version, please update to $v2 or newer.
    unload -rs $qt($script)
  }
  else {
    echo $color(info) -at * Pixel Editor loaded! Type /PE to open the Pixel Editor.
    pe.createicon
  }
}

on *:unload: {
  unset %pixed.*
  pe.close
  .remove $qt($scriptdirCube.ico)
  .remove $qt($scriptdirAutosave.pe)
  echo $color(info) -at * Pixel Editor unloaded!
}

menu menubar {
  Pixel Editor
  .$+(Pixel Editor,$chr(9),/pe):pe
  .-
  .Uninstall:if ($input(Do you really want to uninstall Pixel Editor?,yqu,Pixel Editor)) unload -rs $qt($script)
}

on *:close:@Pixel:pe.close

alias -l pe.close {
  if (%pixed.autosave) && ($window(@Pixel)) {
    bset & 1 $calc(%pixed.width -1)
    pe.getarea 0 0 %pixed.width %pixed.height
    if ($compress(&,bl9m1)) bwrite -c $qt($scriptdirAutosave.pe) 0 -1 &
    else .remove $qt($scriptdirAutosave.pe)
  }
  window -c @Pixel
  hfree -w pe.*
  unset %pe.*
  .timerpe.* off
  window -c @PixelEditor
  if ($dialog(pe.import)) dialog -c $v1
  if ($dialog(pe.export)) dialog -c $v1
  if ($dialog(pe.text)) dialog -c $v1
  while ($window(@pe.*,1)) window -c $v1
  if ($fopen(pixed)) .fclose pixed
}

alias pe {
  if ($window(@Pixel)) window -a @Pixel
  else {
    hfree -w pe.*
    unset %pe.*
    .timerpe.* off
    window -c @PixelEditor
    if ($dialog(pe.import)) dialog -c $v1
    if ($dialog(pe.export)) dialog -c $v1
    if ($dialog(pe.text)) dialog -c $v1
    while ($window(@pe.*,1)) window -c $v1
    if ($fopen(pixed)) .fclose pixed

    hmake pe.cache
    hmake pe.colours 127
    set -l %db $qt($scriptdirPixel Editor.db)
    hmake pe.db
    hmake pe.mirc 127
    set -l %c 98
    while (%c >= 0) {
      hadd pe.colours $rgb($color(%c)) $color(%c)
      hadd pe.mirc $color(%c) %c
      dec %c
    }

    if (%pixed.width !isnum 1-256) %pixed.width = 10
    if (%pixed.height !isnum 1-256) %pixed.height = 10
    if (%pixed.size !isnum 3-) %pixed.size = 25

    %pe.frame = $pe.validatecolour($rgb(frame))
    %pe.text = $pe.validatecolour($rgb(text))
    %pe.inverted = $pe.invert($rgb(text))
    %pe.face = $pe.validatecolour($rgb(face))
    %pe.shadow = $pe.validatecolour($rgb(shadow))
    %pe.3dlight = $pe.validatecolour($rgb(3dlight))
    %pe.transparent = $pe.validatecolour(16711936)
    %pe.background = $color(background)

    set -l %icon $qt($scriptdirCube.ico)
    window -phk0 @pe.mirror -1 -1 -1 -1 %icon
    set -l %file $qt($scriptdirAutosave.pe)
    if (%pixed.autosave) && ($isfile(%file)) {
      bread %file 0 $file(%file).size &
      if ($decompress(&,bm1)) {
        %pixed.width = $bvar(&,1) + 1
        %pixed.height = $int($calc(($bvar(&,0) -1)/%pixed.width))
        pe.checksize
        pe.update
        drawsize @pe.mirror %pe.width %pe.height
        set -l %p 2
        %u = 0
        while ($bvar(&,%p,%pixed.width)) {
          %h = 0
          pe.aline $v1
          inc %u %pixed.size
          inc %p %pixed.width
        }
        unset %h %u
      }
      else {
        .remove $qt($scriptdirAutosave.pe)
        pe.checksize
        pe.update
        drawsize @pe.mirror %pe.width %pe.height
      }
    }
    else {
      pe.checksize
      pe.update
      drawsize @pe.mirror %pe.width %pe.height
    }
    drawline -nr @pe.mirror %pe.frame 1 %pe.grid

    window -pdfk0w0B +ftn @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1) %icon
    titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE

    window -phk0l5 @pe.temp -1 -1 -1 -1 %icon
    window -phk0 @pe.tool -1 -1 -1 -1 %icon
    window -hk0l5 @pe.undo -1 -1 -1 -1 %icon
    window -phk0 @pe.cache -1 -1 -1 -1 %icon
    drawsize @pe.cache 194 228
    drawrect -nfr @pe.cache %pe.face 1 0 0 194 228
    drawline -nr @pe.cache %pe.shadow 1 0 161 0 0 193 0
    drawline -nr @pe.cache %pe.3dlight 1 193 0 193 161 0 161
    set -l %y 1
    set -l %x
    %c = 0
    while (%c <= 15) {
      %x = 1
      while (%x <= 190) {
        drawrect -nf @pe.cache %c 1 %x %y 24 24
        inc %x 24
        inc %c
      }
      inc %y 24
    }
    while (%c <= 98) {
      %x = 1
      while (%x <= 190) {
        drawrect -nf @pe.cache %c 1 %x %y 16 16
        inc %x 16
        inc %c
      }
      inc %y 16
    }
    drawrect -nf @pe.cache 98 1 $calc(%x -16) $calc(%y -16) 16 16

    %x = 1
    %y = 165
    set -l %i 1
    set -l %a
    set -l %b
    while ($gettok($pe.tools,%i,124)) {
      tokenize 1 $v1
      drawline -nr @pe.cache %pe.shadow 1 $calc(1+%x) $calc(30+%y) $calc(1+%x) $calc(1+%y) $calc(30+%x) $calc(1+%y)
      drawline -nr @pe.cache %pe.3dlight 1 $calc(30+%x) $calc(1+%y) $calc(30+%x) $calc(30+%y) $calc(1+%x) $calc(30+%y)
      %a = %x + 1
      %b = %y + 1
      if ($1 == rectangle) {
        drawrect -nr @pe.cache %pe.text 2 $calc(4+%a) $calc(4+%b) 16 16
        drawrect -nr @pe.cache %pe.frame 2 $calc(10+%a) $calc(10+%b) 16 16
      }
      elseif ($1 == filled rectangle) {
        drawrect -nfr @pe.cache %pe.text 2 $calc(4+%a) $calc(4+%b) 16 16
        drawrect -nfr @pe.cache %pe.frame 2 $calc(10+%a) $calc(10+%b) 16 16
      }
      elseif ($1 == focus rectangle) {
        drawrect -nrc @pe.cache %pe.text 2 $calc(4+%a) $calc(4+%b) 16 16
        drawrect -nrc @pe.cache %pe.frame 2 $calc(10+%a) $calc(10+%b) 16 16
      }
      elseif ($1 == ellipse) {
        drawrect -nre @pe.cache %pe.text 2 $calc(4+%a) $calc(4+%b) 16 16
        drawrect -nre @pe.cache %pe.frame 2 $calc(10+%a) $calc(10+%b) 16 16
      }
      elseif ($1 == filled ellipse) {
        drawrect -nfre @pe.cache %pe.text 2 $calc(4+%a) $calc(4+%b) 16 16
        drawrect -nfre @pe.cache %pe.frame 2 $calc(10+%a) $calc(10+%b) 16 16
      }
      elseif ($1 == line) drawline -nr @pe.cache %pe.text 2 $calc(5+%a) $calc(25+%b) $calc(25+%a) $calc(5+%b)
      elseif ($1 == select) drawrect -nrc @pe.cache %pe.text 2 $calc(5+%a) $calc(5+%b) 20 20
      elseif ($1 == text) drawtext -nrc @pe.cache %pe.text Fixedsys -9 $calc(3+%a) $calc(8+%b) 26 26 abc
      elseif ($1 == replace colour) {
        drawrect -nfr @pe.cache %pe.text 2 $calc(4+%a) $calc(4+%b) 11 22
        drawrect -nfr @pe.cache %pe.frame 2 $calc(15+%a) $calc(4+%b) 11 22
        drawline -nr @pe.cache %pe.3dlight 2 $calc(15+%a) $calc(10+%b) $calc(19+%a) $calc(14+%b) $calc(20+%a) $calc(15+%b) $calc(9+%a) $calc(15+%b) $calc(19+%a) $calc(15+%b) $calc(15+%a) $calc(19+%b)
      }
      elseif ($1 == pencil) {
        drawline -nr @pe.cache %pe.text 2 $calc(20+%a) $calc(5+%b) $calc(17+%a) $calc(8+%b) $calc(22+%a) $calc(11+%b) $calc(10+%a) $calc(23+%b) $calc(6+%a) $calc(19+%b) $calc(5+%a) $calc(20+%b) $calc(5+%a) $calc(25+%b) $calc(9+%a) $calc(25+%b) $calc(10+%a) $calc(23+%b) $calc(6+%a) $calc(19+%b) $calc(20+%a) $calc(5+%b) $calc(24+%a) $calc(9+%b) $calc(22+%a) $calc(11+%b)
        drawfill -nr @pe.cache %pe.text %pe.text $calc(9+%a) $calc(19+%b)
      }
      elseif ($1 == colour picker) {
        drawline -nr @pe.cache %pe.text 2 $calc(25+%a) $calc(7+%b) $calc(24+%a) $calc(6+%b) $calc(24+%a) $calc(5+%b) $calc(23+%a) $calc(5+%b) $calc(22+%a) $calc(4+%b) $calc(21+%a) $calc(4+%b) $calc(5+%a) $calc(20+%b) $calc(5+%a) $calc(25+%b) $calc(8+%a) $calc(25+%b) $calc(19+%a) $calc(14+%b) $calc(22+%a) $calc(17+%b) $calc(12+%a) $calc(7+%b) $calc(19+%a) $calc(14+%b) $calc(25+%a) $calc(8+%b)
        drawfill -nr @pe.cache %pe.text %pe.text $calc(20+%a) $calc(8+%b)
      }
      elseif ($1 == fill) {
        drawline -nr @pe.cache %pe.text 2 $calc(22+%a) $calc(6+%b) $calc(16+%a) $calc(12+%b) $calc(18+%a) $calc(10+%b) $calc(15+%a) $calc(7+%b) $calc(7+%a) $calc(15+%b) $calc(17+%a) $calc(25+%b) $calc(25+%a) $calc(17+%b) $calc(18+%a) $calc(10+%b)
        drawline -nr @pe.cache %pe.text 1 $calc(10+%a) $calc(16+%b) $calc(24+%a) $calc(16+%b)
        drawfill -nr @pe.cache %pe.text %pe.text $calc(17+%a) $calc(19+%b)
        drawline -nr @pe.cache %pe.text 1 $calc(6+%a) $calc(18+%b) $calc(5+%a) $calc(19+%b) $calc(5+%a) $calc(20+%b) $calc(4+%a) $calc(21+%b) $calc(4+%a) $calc(22+%b) $calc(6+%a) $calc(24+%b) $calc(8+%a) $calc(22+%b) $calc(8+%a) $calc(21+%b) $calc(7+%a) $calc(20+%b) $calc(7+%a) $calc(18+%b)
        drawfill -nr @pe.cache %pe.text %pe.text $calc(6+%a) $calc(20+%b)
      }
      inc %x 32
      if (%x >= 190) {
        inc %y 32
        %x = 1
      }
      inc %i
    }

    if (%pixed.tool) pe.tool $v1
    else pe.tool pencil
    if (%pixed.colour isnum 0-98) pe.colour $v1
    else pe.colour $color(own)

    pe.mirror
    drawdot @Pixel
  }
}

alias -l pe.aline pe.adraw $*

alias -l pe.adraw drawrect -nf @pe.mirror $1 1 %h %u %pe.rectangle | inc %h %pixed.size

alias -l pe.invert {
  tokenize 44 $rgb($1)
  return $rgb($calc(255*(1-$1 /255)),$calc(255*(1-$2 /255)),$calc(255*(1-$3 /255)))
}

alias -l pe.validatecolour {
  if ($hget(pe.mirc,$1) isnum) {
    tokenize 44 $rgb($1)
    set -l %1 $1
    set -l %2 $2
    set -l %3 $3
    :again
    if (%3 < 255) inc %3
    else %3 = 0
    if ($pe.checkcolour($rgb(%1,%2,%3)) isnum) return $v1
    if (%2 < 255) inc %2
    else %2 = 0
    if ($pe.checkcolour($rgb(%1,%2,%3)) isnum) return $v1
    if (%1 < 255) inc %1
    else %1 = 0
    if ($pe.checkcolour($rgb(%1,%2,%3)) isnum) return $v1
    goto again
  }
  else return $1
}

alias -l pe.checkcolour if (!$hget(pe.mirc,$1)) return $1

alias -l pe.tool {
  if ($findtok($pe.tools,$1-,1,124)) {
    %pe.toolhighlight = $calc(($calc(($v1 -1) % 6))*32+4) $calc($int($calc(($v1 -1)/6)) *32+168) 30 30
    %pixed.tool = $1-
  }
  else {
    %pe.toolhighlight = 36 168 30 30
    %pixed.tool = Pencil
  }
}

alias -l pe.tools return Select|Pencil|Line|Fill|Replace colour|Colour picker|Rectangle|Filled rectangle|Focus rectangle|Ellipse|Filled ellipse|Text

alias -l pe.colour {
  %pixed.colour = $1
  %pe.colour = $color($1)
  if ($1 isnum 0-15) %pe.colourhighlight = $calc(($calc($1 % 8))*24+3) $calc($int($calc($1 /8)) *24+3) 24 24
  elseif ($1 isnum 16-98) %pe.colourhighlight = $calc(($calc(($1 -16) % 12))*16+3) $calc($int($calc(($1 -16)/12)) *16+51) 16 16
  else {
    %pe.colourhighlight = 3 3 24 24
    %pixed.colour = 0
    %pe.colour = 0
  }
  tokenize 44 $rgb($color(%pixed.colour))
  %pe.hilight = $iif($calc(0.2126*$1 +0.7152*$2 +0.0722*$3) >= 125,0,16777215)
}

alias -l pe.panel {
  drawrect -nrf @Pixel %pe.face 1 0 0 199 %pe.height
  drawline -nr @Pixel %pe.frame 1 199 0 199 %pe.height
  drawcopy -n @pe.cache 0 0 194 228 @Pixel 2 2
  drawrect -nr @Pixel %pe.hilight 1 %pe.colourhighlight
  drawrect -nr @Pixel %pe.text 1 %pe.toolhighlight
}

alias -l pe.mirror {
  drawcopy -n @pe.mirror 0 0 %pe.width %pe.height @Pixel 200 0
  drawrect -nrf @Pixel %pe.face 1 0 0 199 %pe.height
  drawline -nr @Pixel %pe.frame 1 199 0 199 %pe.height
  drawcopy -n @pe.cache 0 0 194 228 @Pixel 2 2
  drawrect -nr @Pixel %pe.hilight 1 %pe.colourhighlight
  drawrect -nr @Pixel %pe.text 1 %pe.toolhighlight
}

alias -l pe.grid {
  set -l %w $1 * %pixed.size
  set -l %h $2 * %pixed.size
  set -l %x %pixed.size - 1
  if ($3) {
    inc %w $3
    inc %x $3
  }
  set -l %l
  while (%x < %w) {
    %l = %l %x -1 %x %h
    inc %x %pixed.size
    %l = %l %x %h %x -1
    inc %x %pixed.size
  }
  set -l %y -1
  while (%y < %h) {
    %l = %l %w %y -1 %y
    inc %y %pixed.size
    %l = %l -1 %y %w %y
    inc %y %pixed.size
  }
  return %l
}

on *:keydown:@Pixel:17:%pe.ctrl = 1

on *:keyup:@Pixel:17:unset %pe.ctrl

on *:keydown:@Pixel:16:%pe.shift = 1

on *:keyup:@Pixel:16:unset %pe.shift

alias -l pe.unset unset %pe.tool %pe.ctrl %pe.shift

;+-
on *:keydown:@Pixel:107,109: pe.changesize $keyval

alias -l pe.changesize {
  if (%pe.tool) || (%pe.copy) {
    beep 1
    return
  }
  %size = %pixed.size
  if ($1 == 107) inc %pixed.size
  else {
    if (%pixed.size > 3) && ($calc(%pixed.size *(%pixed.height -1)) >= 230) dec %pixed.size
    else {
      beep 1
      return
    }
  }
  pe.tip Processing...
  clear -n @pe.temp
  drawsize @pe.temp %pe.width %pe.height
  drawcopy -n @pe.mirror 0 0 %pe.width %pe.height @pe.temp 0 0

  %pe.rectangle = %pixed.size - 1
  %pe.rectangle = %pe.rectangle %pe.rectangle
  pe.update

  clear -n @pe.mirror
  drawsize @pe.mirror %pe.width %pe.height
  drawline -nr @pe.mirror %pe.frame 1 %pe.grid

  %y = 0
  %b = 0
  set -l %tokens $str(x $chr(32),$calc(%pixed.width -1))
  tokenize 46 $str(x.,%pixed.height)
  pe.pline $* %tokens
  unset %x %a %y %b %size

  window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
  pe.mirror
  drawdot @Pixel
}

alias -l pe.pline %x = 0 | %a = 0 | pe.gdot $* | inc %y %size | inc %b %pixed.size

alias -l pe.gdot drawrect -rnf @pe.mirror $getdot(@pe.temp,%x,%y) 1 %a %b %pe.rectangle | inc %x %size | inc %a %pixed.size

alias -l pe.tip {
  if ($mouse.x >= 200) pe.imagetip $1-
  else pe.paneltip $1-
  drawdot @Pixel
}

alias -l pe.imagetip {
  set -l %w $width($1-,Tahoma,12,p) + 2
  set -l %h $height($1-,Tahoma,12,p) + 2
  set -l %x $mouse.x + 10
  set -l %y $mouse.y + 20
  if ($calc(%x +%w) > $window(@Pixel).dw) %x = $v2 - %w
  if (%x < 200) %x = 200
  if ($calc(%y +%h) > $window(@Pixel).dh) %y = %y - 40
  drawtext -rbnp @Pixel %pe.text %pe.inverted Tahoma 12 $calc(1+%x) $calc(1+%y) $1-
  drawrect -rn @Pixel %pe.frame 1 %x %y %w %h
  %pe.tip = 1
}

alias -l pe.paneltip {
  set -l %w $width($1-,Tahoma,12,p) + 2
  set -l %h $height($1-,Tahoma,12,p) + 2
  set -l %x $mouse.x + 10
  set -l %y $mouse.y + 20
  if ($calc(%x +%w) > 199) %x = 199 - %w
  drawtext -rbnp @Pixel %pe.text %pe.inverted Tahoma 12 $calc(1+%x) $calc(1+%y) $1-
  drawrect -rn @Pixel %pe.frame 1 %x %y %w %h
  %pe.tip = 2
}

#pe.method1 on
alias -l pe.match {
  if ($hget(pe.db,$1) isnum) return $v1
  set -l %a $1
  set -l %b a
  set -l %n 0
  tokenize 44 $rgb($1)
  set -l %x 1
  set -l %1 $1
  set -l %2 $2
  set -l %3 $3
  while ($hget(pe.colours,%x).item) {
    tokenize 44 $v1
    if ($calc(($1 -%1)^2+($2 -%2)^2+($3 -%3)^2) < %b) var %b = $v1,%n %x
    inc %x
  }
  hadd pe.db %a $hget(pe.colours,%n).data
  return $hget(pe.colours,%n).data
}
#pe.method1 end

#pe.method2 off
alias -l pe.match {
  if ($hget(pe.db,$1) isnum) return $v1
  set -l %a $1
  set -l %b a
  set -l %n 0
  tokenize 44 $rgb($1)
  set -l %1 $1
  set -l %2 $2
  set -l %3 $3
  set -l %x 1
  while ($hget(pe.colours,%x).item) {
    tokenize 44 $v1
    if ($calc((($1 -%1)*0.3)^2+(($2 -%2)*0.59)^2+(($3 -%3)*0.11)^2) < %b) var %b = $v1,%n %x
    inc %x
  }
  hadd pe.db %a $hget(pe.colours,%n).data
  return $hget(pe.colours,%n).data
}
#pe.method2 end

dialog -l pe.new {
  title "Pixel Editor - New"
  icon $scriptdirCube.ico
  size -3 -1 157 71
  option map
  text "Width:", 1, 10 10 24 11
  combo 2, 36 9 35 14, drop
  text "Height:", 3, 85 10 26 11
  combo 4, 112 9 35 14, drop
  text "Size:", 5, 10 28 24 11
  combo 6, 36 27 35 14, drop
  button "Cancel", 7, 97 47 50 16, cancel
  button "OK", 8, 46 47 50 16, default ok
}

on *:dialog:pe.new:init:0: {
  set -l %x 1
  set -l %l
  while (%x <= 256) {
    %l = %l %x
    inc %x
  }
  didtok pe.new 2,4 32 %l
  if ($didwm(2,%pixed.width)) did -c pe.new 2 $v1
  else did -ca pe.new 2 %pixed.width
  if ($didwm(4,%pixed.height)) did -c pe.new 4 $v1
  else did -ca pe.new 4 %pixed.height
  didtok pe.new 6 32 $gettok(%l,3-50,32)
  if ($didwm(6,%pixed.size)) did -c pe.new 6 $v1
  else did -ca pe.new 6 %pixed.size
}

on *:dialog:pe.new:sclick:8: {
  pe.clearredo
  pe.clearundo
  unset %pe.copy
  %pixed.width = $did(2)
  %pixed.height = $did(4)
  %pixed.size = $did(6)
  %pe.rectangle = %pixed.size - 1
  %pe.rectangle = %pe.rectangle %pe.rectangle
  pe.update
  drawsize @pe.mirror %pe.width %pe.height
  drawrect -fn @pe.mirror %pe.background 1 0 0 %pe.width %pe.height
  drawline -nr @pe.mirror %pe.frame 1 %pe.grid
  window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
  pe.mirror
  drawdot @Pixel
}

;CTRL+S
on *:keydown:@Pixel:83:if (%pe.ctrl) pe.exportimage

alias -l pe.exportimage {
  if ($sfile($iif($isdir(%pixed.exportpath),%pixed.exportpath,$mircdir) $+ Pixed $ticks $+ .bmp,Pixel Editor - Export as image file,Save)) {
    tokenize 1 $v1
    %pixed.exportpath = $nofile($v1)
    pe.tip Processing...
    clear -n @pe.temp
    drawsize @pe.temp %pixed.width %pixed.height
    set -l %x
    set -l %a
    set -l %y 0
    set -l %b 0
    while (%b < %pixed.height) {
      %x = 0
      %a = 0
      while (%a < %pixed.width) {
        drawdot -rn @pe.temp $getdot(@pe.mirror,%x,%y) 1 %a %b
        inc %x %pixed.size
        inc %a
      }
      inc %y %pixed.size
      inc %b
    }
    drawsave -b32 @pe.temp $qt($1)
  }
}

;CTRL+E
on *:keydown:@Pixel:69:if (%pe.ctrl) pe.exporttext

alias -l pe.exporttext {
  if ($sfile($iif($isdir(%pixed.exportpath),%pixed.exportpath,$mircdir) $+ Pixed $ticks $+ .txt,Pixel Editor - Export as text file,Save)) {
    %pixed.exportpath = $nofile($v1)
    set -u %pe.export text $v1
    noop $dialog(pe.export,pe.export,-3)
  }
}

;CTRL+P
on *:keydown:@Pixel:80: {
  if (%pe.ctrl) {
    set -u %pe.export preview
    noop $dialog(pe.export,pe.export,-3)
  }
}

dialog -l pe.export {
  title "Pixel Editor - Export"
  icon $scriptdirCube.ico
  size -1 -1 228 114
  option map
  text "Target:", 1, 4 7 43 11, right
  combo 2, 50 5 171 150, drop
  text "Encoding:", 3, 4 24 43 11, right
  combo 4, 50 22 78 100, drop
  link "Help", 5, 132 23 18 11
  text "Filler:", 6, 4 41 43 11, right
  combo 7, 50 39 78 100, drop edit limit 10
  text "Transparent:", 8, 4 58 43 11, right
  combo 9, 50 56 78 100, drop
  link "Help", 10, 132 57 18 11
  text "Delay:", 11, 4 75 43 11, right
  combo 12, 50 73 78 100, drop edit limit 5
  text "milliseconds", 13, 131 75 96 11
  button "Pause", 14, 69 91 50 16, disable
  button "Start", 15, 120 91 50 16, default
  button "Cancel", 16, 171 91 50 16, cancel
  text "", 17, 1 94 67 11, center
}

on *:dialog:pe.export:init:0: {
  set -l %x 1
  if ($status == connected) {
    didtok pe.export 2 44 Clipboard,File...,Status window,Preview,/wallops
    while ($chan(%x)) { did -a pe.export 2 Channel: $v1 | inc %x }
    %x = 1
    while ($query(%x)) { did -a pe.export 2 Query: $v1 | inc %x }
  }
  else   didtok pe.export 2 44 Clipboard,File...,Status window,Preview
  %x = 1
  while ($chat(%x)) { did -a pe.export 2 DCC: $v1 | inc %x }
  %x = 1
  while ($window(%x).type) {
    if ($v1 == custom) && ($window(%x).state != hidden) did -a pe.export 2 Window: $window(%x)
    inc %x
  }
  if (%pe.export == clipboard) did -c pe.export 2 1
  elseif (text * iswm  %pe.export) did -co pe.export 2 2 File: $gettok($v2,2-,32)
  elseif (%pe.export == preview) did -c pe.export 2 4
  elseif ($didwm(2,*: $active)) || ($didwm(2,*: $lactive)) did -c pe.export 2 $v1
  elseif ($active == status window) || ($lactive == status window) did -c pe.export 2 3
  else did -c pe.export 2 3
  didtok pe.export 4 44 Basic,Double (vertical),Double (horizontal)
  if ($didwm(4,%pixed.encoding)) did -c pe.export 4 $v1
  else did -c pe.export 4 2
  didtok pe.export 7 44 <nbsp>,<nbsp><nbsp>,@,I
  if (%pixed.filler == $null) %pixed.filler = @
  if ($didwm(7,%pixed.filler)) did -c pe.export 7 $v1
  else did -ca pe.export 7 %pixed.filler
  didtok pe.export 9 32 none 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98
  if ($didwm(9,%pixed.transparent)) did -c pe.export 9 $v1
  else did -c pe.export 9 1
  didtok pe.export 12 32 0 250 500 1000 2000 3000 4000 5000 7500 10000
  if (%pixed.delay !isnum 0-99999) %pixed.delay = 3000
  if ($didwm(12,%pixed.delay)) did -c pe.export 12 $v1
  else did -ca pe.export 12 %pixed.delay
  pe.exportcheck
  if (%pe.export == preview) pe.export
}

on *:dialog:pe.export:close:0: {
  .timerpe.export off
  .timerpe.activate off
  window -c @PixelEditor Preview
  if ($fopen(pixed)) .fclose pixed
}

alias -l pe.exportcheck {
  if (%pixed.encoding == basic) {
    did -e pe.export 6,7
    if ($istok(<nbsp> <nbsp><nbsp>,%pixed.filler,32)) did -e pe.export 8,9
    else did -b pe.export 8,9
    did -ra pe.export 13 milliseconds ( $+ $duration($calc((%pixed.height *%pixed.delay)/1000)) $+ )
  }
  elseif (%pixed.encoding == double (horizontal)) {
    did -b pe.export 6,7,8,9
    did -ra pe.export 13 milliseconds ( $+ $duration($calc((%pixed.height *%pixed.delay)/1000)) $+ )
  }
  else {
    did -b pe.export 6,7,8,9
    did -ra pe.export 13 milliseconds ( $+ $duration($calc(((%pixed.height /2) *%pixed.delay)/1000)) $+ )
  }
  if (*?: ?* iswm $did(pe.export,2)) && (File: * !iswm $v2) did -e pe.export 11,12,13
  else did -b pe.export 11,12,13
}

on *:dialog:pe.export:sclick:2: {
  if (file* iswm $did(2)) {
    if ($sfile($iif($isdir(%pixed.exportpath),%pixed.exportpath,$mircdir) $+ Pixed $ticks $+ .txt,Pixel Editor - Export as text file,Save)) {
      %pixed.exportpath = $nofile($v1)
      did -co pe.export 2 $did(2).sel File: $v1
    }
    else {
      did -o pe.export 2 $did(2).sel File...
      did -c pe.export 2 1
    }
  }
  pe.exportcheck
}

on *:dialog:pe.export:sclick:4:%pixed.encoding = $did(4) | pe.exportcheck

on *:dialog:pe.export:sclick:5:pe.encodinginput

on *:dialog:pe.export:sclick:7:%pixed.filler = $did(7) | pe.exportcheck

on *:dialog:pe.export:sclick:9:%pixed.transparent = $did(9)

on *:dialog:pe.export:sclick:10: {
  set -l %m Transparent colour will not be filled in, and lines ending with it, will be chopped at the last colour transition point.
  noop $input($replacex(%m,\n,$crlf),oiu,Pixel Editor)
}

on *:dialog:pe.export:sclick,edit:12: {
  %pixed.delay = $iif($did(12) isnum 0-,$v1,3000)
  if ($timer(pe.export)) .timerpe.export -om 0 %pixed.delay pe.line
  else pe.exportcheck
}

on *:dialog:pe.export:sclick:14: {
  if ($did(14) == pause) {
    .timerpe.export -p
    did -ra pe.export 14 Unpause
  }
  else {
    .timerpe.export -r
    did -ra pe.export 14 Pause
  }
}

on *:dialog:pe.export:sclick:15:pe.export

alias -l pe.export {
  if ($did(pe.export,15) == stop) {
    did -e pe.export 1-5,10
    pe.exportcheck
    did -b pe.export 14
    did -ra pe.export 15 Start
    did -ra pe.export 17 Stopped.
    .timerpe.export 1 2 did -r pe.export 17
    if ($fopen(pixed)) .fclose pixed
  }
  else {
    did -b pe.export 1-10
    did -e pe.export 14
    did -ra pe.export 15 Stop
    tokenize 1 $did(pe.export,2)
    if ($1 == clipboard) {
      clipboard
      tokenize 32 0 clipboard -an
    }
    elseif ($1 == status window) tokenize 32 0 echo -s
    elseif ($1 == /wallops) tokenize 32 %pixed.delay /wallops
    elseif (Channel: * iswm $1) || (Query: * iswm $1) tokenize 32 %pixed.delay msg $gettok($1,2,32)
    elseif (DCC: * iswm $1) tokenize 32 %pixed.delay msg = $+ $gettok($1,2,32)
    elseif (Window: * iswm $1) tokenize 32 %pixed.delay aline $gettok($1,2,32)
    elseif (File: * iswm $1) {
      set -l %f $qt($gettok($1,2-,32))
      if ($fopen(pixed)) .fclose pixed
      .fopen -o pixed %f
      tokenize 32 0 .fwrite -n pixed
    }
    else {
      window -zk0dafw0 +bLstxn @PixelEditor 0 0 900 $calc($height($chr(9608),$window(status window).font,$window(status window).fontsize)*($iif($did(pe.export,4) == double (vertical),$calc(%pixed.height /2),%pixed.height)+2)) $qt($scriptdirCube.ico)
      titlebar @PixelEditor Preview
      tokenize 32 0 pe.preview
      %pe.lines = $line(@PixelEditor,0) + 1
      .timerpe.activate -om 1 0 window -a @PixelEditor
    }
    %pe.y = 0
    %pe.filler = $replacex(%pixed.filler,<nbsp>,$chr(160))
    %pe.line = 0
    %pe.cmd = $2-
    if ($did(pe.export,4) == basic) {
      if (%pixed.transparent isnum 0-98) && ($remove(%pe.filler,$chr(160)) == $null) %pe.encoding = pe.basictransparent
      else %pe.encoding = pe.basic
    }
    elseif ($did(pe.export,4) == double (vertical)) %pe.encoding = pe.doublevertical
    else %pe.encoding = pe.doublehorizontal
    .timerpe.export -om 0 $1 pe.line
    pe.line
  }
}

alias -l pe.bytes bset -tc & 1 $1 | return $bvar(&,0)

alias -l pe.preview aline @PixelEditor $1- $+  $pe.bytes($1-) bytes

alias -l pe.line {
  if (%pe.y < %pe.height) {
    %pe.encoding
    did -ra pe.export 17 %pe.line of %pixed.height
  }
  if (%pe.y >= %pe.height) pe.endspam
}

alias -l pe.endspam {
  .timerpe.export off
  if ($fopen(pixed)) .fclose pixed
  if ($did(pe.export,2) == preview) {
    did -e pe.export 1-5,10
    pe.exportcheck
    did -b pe.export 14
    did -ra pe.export 15 Start
    did -ra pe.export 17 Finished.
    .timerpe.export 1 2 did -r pe.export 17
    set -l %longest 0
    set -l %line
    while ($line(@PixelEditor,%pe.lines)) {
      tokenize 1 $gettok($gettok($v1,-1,15),1,32)
      if ($1 > %longest) {
        %longest = $v1
        %line = %pe.lines
      }
      elseif ($1 == %longest) %line = %line %pe.lines
      inc %pe.lines
    }
    set -l %d
    tokenize 32 %line
    while ($1) {
      %d = $line(@PixelEditor,$1)
      rline @PixelEditor $1 %d (longest)
      tokenize 32 $2-
    }
  }
  else dialog -c pe.export
}

alias -l pe.basictransparent {
  inc %pe.line
  set -l %x 0
  set -l %line
  set -l %o
  while (%x < %pe.width) {
    if ($hget(pe.mirc,$getdot(@pe.mirror,%x,%pe.y)) != %o) {
      %o = $v1
      if (%o == %pixed.transparent) %line = $+(%line,$chr(3),%pe.filler)
      else %line = $+(%line,$chr(3),0,$chr(44),%o,%pe.filler)
    }
    else %line = %line $+ %pe.filler
    inc %x %pixed.size
  }
  if (%o == %pixed.transparent) %line = $chr(3) $+ $gettok(%line,-2--,3)
  inc %pe.y %pixed.size
  %pe.cmd %line
}

alias -l pe.basic {
  inc %pe.line
  set -l %x 0
  set -l %line
  set -l %o
  while (%x < %pe.width) {
    if ($hget(pe.mirc,$getdot(@pe.mirror,%x,%pe.y)) != %o) {
      %o = $v1
      %line = $+(%line,$chr(3),$v1,$chr(44),$v1,%pe.filler)
    }
    else %line = %line $+ %pe.filler
    inc %x %pixed.size
  }
  inc %pe.y %pixed.size
  %pe.cmd %line
}

alias -l pe.brightness {
  tokenize 44 $rgb($color($1))
  return $sqrt($calc((0.299*$1 ^2)+(0.587*$2 ^2)+(0.114*$3 ^2)))
}

alias -l pe.doublevertical {
  inc %pe.line 2
  set -l %line
  set -l %txt
  set -l %bg
  set -l %row1 %pe.y
  inc %pe.y %pixed.size
  set -l %row2 %pe.y
  inc %pe.y %pixed.size
  set -l %x 0
  if (%row2 < %pe.height) {
    while (%x < %pe.width) {
      tokenize 32 $hget(pe.mirc,$getdot(@pe.mirror,%x,%row1)) $hget(pe.mirc,$getdot(@pe.mirror,%x,%row2))
      if ($1 == $2) tokenize 32 $1 $1 $chr(9608)
      elseif ($pe.brightness($1) > $pe.brightness($2)) tokenize 32 $1 $2 $chr(9600)
      else tokenize 32 $2 $1 $chr(9604)
      if ($2 == %bg) {
        if ($1 == %txt) %line = %line $+ $3
        else %line = $+(%line,$chr(3),$1,$3)
      }
      else %line = $+(%line,$chr(3),$1,$chr(44),$2,$3)
      %txt = $1
      %bg = $2
      inc %x %pixed.size
    }
  }
  else {
    while (%x < %pe.width) {
      tokenize 32 $hget(pe.mirc,$getdot(@pe.mirror,%x,%row1))
      if ($1 == %txt) %line = %line $+ $chr(9600)
      else %line = $+(%line,$chr(3),$1,$chr(44),$color(background),$chr(9600))
      %txt = $1
      inc %x %pixed.size
    }
  }
  %pe.cmd %line
}

alias -l pe.doublehorizontal {
  inc %pe.line
  set -l %line
  set -l %1
  set -l %2
  set -l %txt
  set -l %bg
  set -l %x 0
  set -l %y %pe.y
  inc %pe.y %pixed.size
  while (%x < %pe.width) {
    tokenize 32 $hget(pe.mirc,$getdot(@pe.mirror,%x,%y))
    inc %x %pixed.size
    if ($hget(pe.mirc,$getdot(@pe.mirror,%x,%y)) isnum) tokenize 32 $1 $v1
    else tokenize 32 $1 $1
    inc %x %pixed.size
    if ($1 == $2) tokenize 32 $1 $1 $chr(9608)
    elseif ($pe.brightness($1) > $pe.brightness($2)) tokenize 32 $1 $2 $chr(9616)
    else tokenize 32 $2 $1 $chr(9612)
    if ($2 == %bg) {
      if ($1 == %txt) %line = %line $+ $3
      else %line = $+(%line,$chr(3),$1,$3)
    }
    else %line = $+(%line,$chr(3),$1,$chr(44),$2,$3)
    %txt = %1
    %bg = %2
  }
  %pe.cmd %line
}

;CTRL+Z
on *:keydown:@Pixel:90:if (%pe.ctrl) pe.undo

alias -l pe.undo {
  if (!%pe.tool) && (!%pe.copy) && ($line(@pe.undo,1)) {
    $line(@pe.undo,1)
    dline @pe.undo 1
    drawcopy -n @pe.mirror 0 0 %pe.width %pe.height @Pixel 200 0
    drawdot @Pixel
  }
  else beep 1
}

;CTRL+Y
on *:keydown:@Pixel:89:if (%pe.ctrl) pe.redo

alias -l pe.redo {
  if (!%pe.tool) && (!%pe.copy) && ($line(@pe.undo,1,1)) {
    $line(@pe.undo,1,1)
    dline -l @pe.undo 1
    drawcopy -n @pe.mirror 0 0 %pe.width %pe.height @Pixel 200 0
    drawdot @Pixel
  }
  else beep 1
}

alias -l pe.clearredo {
  hdel -w pe.cache redo????????????????????????????????????????
  clear -l @pe.undo
}

alias -l pe.clearundo {
  hdel -w pe.cache undo????????????????????????????????????????
  clear @pe.undo
}

menu @PixelEditor {
  Clear:clear @PixelEditor
  -
  Close:window -c @PixelEditor
}

menu @Pixel {
  mouse:pe.mouse
  sclick:pe.sclick
  uclick:if (!$istok(replace colour|colour picker,%pixed.tool,124)) pe.finish
  leave:pe.finish

  New:noop $dialog(pe.new,pe.new,-3)
  -
  Tools
  .$iif(%pixed.tool == select,$style(1)) Select:pe.tool select
  .$iif(%pixed.tool == pencil,$style(1)) Pencil:pe.tool pencil
  .$iif(%pixed.tool == line,$style(1)) Line:pe.tool line
  .$iif(%pixed.tool == fill,$style(1)) Fill:pe.tool fill
  .$iif(%pixed.tool == replace colour,$style(1)) Replace colour:pe.tool replace colour
  .$iif(%pixed.tool == colour picker,$style(1)) Colour picker:pe.tool colour picker
  .$iif(%pixed.tool == rectangle,$style(1)) Rectangle:pe.tool rectangle
  .$iif(%pixed.tool == filled rectangle,$style(1)) Filled rectangle:pe.tool filled rectangle
  .$iif(%pixed.tool == focus rectangle,$style(1)) Focus rectangle:pe.tool focus rectangle
  .$iif(%pixed.tool == ellipse,$style(1)) Ellipse:pe.tool ellipse
  .$iif(%pixed.tool == fill edellipse,$style(1)) Filled ellipse:pe.tool filled ellipse
  .Text:noop $dialog(pe.text,pe.text,-3)
  -
  Flip...
  .$+(horizontally,$chr(9),CTRL+H):pe.horflip | pe.clearredo
  .vertically:pe.verflip | pe.clearredo
  Rotate...
  .$+(90° clockwise,$chr(9),CTRL+R):pe.rotate 90 | pe.clearredo
  .180°:pe.rotate 180 | pe.clearredo
  .90° counter clockwise:pe.rotate -90 | pe.clearredo
  Resize
  .$iif(%pixed.highquality,$style(1)) High quality mode: {
    if (%pixed.highquality) unset %pixed.highquality
    else %pixed.highquality = 1
  }
  .-
  .25%:pe.resize 0.25 | pe.clearredo
  .50%:pe.resize 0.5 | pe.clearredo
  .75%:pe.resize 0.75 | pe.clearredo
  .-
  .125%:pe.resize 1.25 | pe.clearredo
  .150%:pe.resize 1.5 | pe.clearredo
  .175%:pe.resize 1.75 | pe.clearredo
  .200%:pe.resize 2 | pe.clearredo
  -
  Add..
  .$+(a row to top,$chr(9),SHIFT+UP):pe.addtop | pe.clearredo
  .$+(a row to bottom,$chr(9),SHIFT+DOWN):pe.addbottom | pe.clearredo
  .-
  .$+(a column to left,$chr(9),SHIFT+LEFT):pe.addleft | pe.clearredo
  .$+(a column to right,$chr(9),SHIFT+RIGHT):pe.addright | pe.clearredo

  Remove...
  .$+(a row from top,$chr(9),CTRL+UP):pe.removetop | pe.clearredo
  .$+(a row from bottom,$chr(9),CTRL+DOWN):pe.removebottom | pe.clearredo
  .-
  .$+(a column from left,$chr(9),CTRL+LEFT):pe.removeleft | pe.clearredo
  .$+(a column from right,$chr(9),CTRL+RIGHT):pe.removeright | pe.clearredo
  -
  $+(Increase size,$chr(9),+):pe.changesize 107
  $+(Decrease size,$chr(9),-):pe.changesize
  -
  -
  $iif(!$line(@pe.undo,1),$style(2)) $+(Undo,$chr(9),CTRL+Z):pe.undo
  $iif(!$line(@pe.undo,1,1),$style(2)) $+(Redo,$chr(9),CTRL+Y):pe.undo
  -
  Import from...
  .clipboard: {
    if ($cb(0)) {
      set -u %pe.import clipboad
      noop $dialog(pe.import,pe.import,-3)
    }
    else noop $input(Clipboard is empty.,oiu,Pixel Editor)
  }
  .$+(image file,$chr(9),CTRL+I):pe.import
  .text file: {
    if ($sfile($iif($isdir(%pixed.lasttext),%pixed.lasttext,$mircdir) $+ *.txt;*.log,Choose a text file to import,Select)) {
      set -u %pe.import text $v1
      noop $dialog(pe.import,pe.import,-3)
    }
  }
  Export to...
  .$+(preview,$chr(9),CTRL+P):set -u %pe.export preview | noop $dialog(pe.export,pe.export,-3)
  .-
  .clipboard:set -u %pe.export clipboard | noop $dialog(pe.export,pe.export,-3)
  .$+(image file,$chr(9),CTRL+S):pe.exportimage
  .text file:pe.exporttext
  .$+(window,$chr(9),CTRL+E):set -u %pe.export window | noop $dialog(pe.export,pe.export,-3)
  -
  $iif(%pixed.autosave,$style(1)) Autosave: {
    if (%pixed.autosave) {
      unset %pixed.autosave
      .remove $qt($scriptdirAutosave.pe)
    }
    else %pixed.autosave = 1
  }
  -
  Close:pe.close
}

alias -l pe.sclick {
  %pe.mx = $mouse.x
  %pe.my = $mouse.y
  %pe.y = $floor($calc(%pe.my /%pixed.size))
  %pe.ry = %pe.y * %pixed.size
  if (%pe.mx >= 200) {
    %pe.x = $floor($calc((%pe.mx -200)/%pixed.size))
    %pe.rx = %pe.x * %pixed.size
    %pe.tool = %pixed.tool
    if (%pe.tool == select) {
      if (%pe.copy) {
        tokenize 32 $v1
        if ($inrect(%pe.x,%pe.y,$1,$2,$3,$4)) {
          %pe.tool = selectmove
          %pe.offsetx = %pe.x - $1
          %pe.offsety = %pe.y - $2
          set -l %tip pe.imagetip X: $1 Y: $2 WH: $3 x $4
        }
        else {
          pe.savearea %pe.copy
          unset %pe.copy
          drawcopy -nt @pe.tool %pe.transparent 0 0 $calc($3 *%pixed.size) $calc($4 *%pixed.size) @pe.mirror $calc($1 *%pixed.size) $calc($2 *%pixed.size)
        }
      }
      else {
        %pe.select = %pe.x %pe.y 1 1
        dec %pe.rx
        dec %pe.ry
        %pe.ax = %pe.x
        %pe.ay = %pe.y
        drawline -rn @pe.mirror %pe.frame 1 %pe.grid
        drawrect -crn @pe.mirror %pe.3dlight 1 %pe.rx %pe.ry $calc(1+%pixed.size) $calc(1+%pixed.size)
        set -l %tip pe.imagetip 1 x 1
      }
    }
    elseif (%pe.tool == pencil) {
      pe.clearredo
      if (%pe.colour != $getdot(@pe.mirror,%pe.rx,%pe.ry)) pe.drawdot $v1 $v2 %pe.x %pe.y
      set -l %tip pe.imagetip X: %pe.x Y: %pe.y
    }
    elseif ($istok(line|rectangle|filled rectangle|ellipse|filled ellipse|focus rectangle,%pixed.tool,124)) {
      pe.clearredo
      clear -n @pe.tool
      drawsize @pe.tool %pixed.width %pixed.height
      %pe.ax = %pe.x
      %pe.ay = %pe.y
      set -l %tip pe.imagetip X: %pe.x Y: %pe.y
      if (%pe.tool == focus rectangle) %pe.parms = -crn
      elseif (%pe.tool == rectangle) %pe.parms = -rn
      elseif (%pe.tool == filled rectangle) %pe.parms = -frn
      elseif (%pe.tool == ellipse) %pe.parms = -ern
      else %pe.parms = -fern
    }
    elseif (%pixed.tool == fill) {
      pe.clearredo
      pe.imagetip Processing...
      drawdot @Pixel
      %r = %pixed.size %pixed.size
      %y = 0
      set -l %tokens $str(x $chr(32),$calc(%pixed.width -1))
      tokenize 32 $str(x $chr(32),%pixed.height)
      pe.fillline $* %tokens
      unset %x %y %r
      set -l %h undo $+ $sha1($ticksqpc)
      hadd -b pe.cache %h &
      iline @pe.undo 1 .pe.drawarea 0 0 %pixed.width %pixed.height %h
      drawfill -nsr @pe.mirror %pe.colour $getdot(@pe.mirror,%pe.rx,%pe.ry) %pe.rx %pe.ry
      drawline -nr @pe.mirror %pe.frame 1 %pe.grid
    }
    elseif (%pixed.tool == replace colour) {
      unset %pe.tool
      set -l %tip $pe.replace($getdot(@pe.mirror,%pe.rx,%pe.ry))
    }
    elseif (%pixed.tool == colour picker) {
      unset %pe.tool
      set -l %c $getdot(@pe.mirror,%pe.rx,%pe.ry)
      set -l %tip pe.imagetip mIRC: $hget(pe.mirc,%c) RGB: $rgb(%c)    
      pe.colour $hget(pe.mirc,%c)
    }
  }
  else {
    %pe.x = 0
    %pe.rx = 0
    if (%pe.mx isnum 3-194) && (%pe.my isnum 3-162) {
      drawcopy -n @pe.cache 0 0 194 228 @Pixel 2 2
      if ($hget(pe.mirc,$getdot(@Pixel,%pe.mx,%pe.my)) isnum 0-98) {
        set -l %c $v1
        if (%pixed.tool == replace colour) set -l %tip $pe.replace($getdot(@Pixel,%pe.mx,%pe.my),1)
        else pe.colour %c
      }
    }
    elseif (%pe.mx isnum 5-194) && (%pe.my isnum 169-231) {
      tokenize 32 %pe.mx %pe.my $int($calc((%pe.mx -5)/32)) $int($calc((%pe.my -169)/32))
      if ($inrect($1,$2,$calc($3 *32+4),$calc($4 *32+168),30,30)) {
        set -l %t $gettok($pe.tools,$calc((1+$3)+6*$4),124)
        pe.tool %t
        unset %pe.replace
        drawline -nr @pe.mirror %pe.frame 1 %pe.grid
        if (%t == text) noop $dialog(pe.text,pe.text,-3)
        elseif (%t != select) && (%pe.copy) pe.finishcopy
      }
    }
  }
  drawcopy -n @pe.mirror 0 0 %pe.width %pe.height @Pixel 200 0
  if (%pe.copy) pe.copy $v1
  elseif (%pe.tool == line) drawrect -frn @Pixel %pe.colour 1 $calc(200+%pe.rx) %pe.ry %pe.rectangle
  pe.panel
  if (%tip) $v1
  drawdot @Pixel
}

alias -l pe.copy {
  set -l %x $1 * %pixed.size
  set -l %y $2 * %pixed.size
  set -l %w $3 * %pixed.size
  set -l %h $4 * %pixed.size
  inc %x 200
  drawcopy -nt @pe.tool %pe.transparent 0 0 %w %h @Pixel %x %y
  dec %x
  dec %y
  inc %w
  inc %h
  drawrect -rn @pixel %pe.3dlight 1 %x %y %w %h
}

alias -l pe.drawdot {
  if ($show) iline @pe.undo 1 .pe.drawdot $2 $1 $3-
  else iline -l @pe.undo 1 pe.drawdot $2 $1 $3-
  drawrect -nrf @pe.mirror $1 1 $calc($3 *%pixed.size) $calc($4 *%pixed.size) %pe.rectangle
}

alias -l pe.fillline %x = 0 | pe.filldot $* | inc %y %pixed.size

alias -l pe.filldot {
  tokenize 1 $getdot(@pe.mirror,%x,%y)
  bset & -1 $hget(pe.mirc,$1)
  drawrect -nrf @pe.mirror $1 1 %x %y %r
  inc %x %pixed.size
}

alias -l pe.replace {
  if ($2) set -l %type pe.paneltip
  else set -l %type pe.imagetip
  set -l %c $hget(pe.mirc,$1)
  if (%pe.replace isnum) {
    pe.clearredo
    pe.replacecolour %pe.replace %c
    unset %pe.replace
    pe.colour %c
    return %type $+(Replace colour,%c %c,...)
  }
  else {
    %pe.replace = %c
    pe.colour %c
    return %type $+(Replace colour,%c %c with colour,%c %c,...)
  }
}

alias -l pe.replacecolour {
  if ($show) iline @pe.undo 1 .pe.replacecolour $2 $1
  else iline -l @pe.undo 1 pe.replacecolour $2 $1
  drawreplace -n @pe.mirror $1-2 0 0 %pe.width %pe.height
}

dialog -l pe.text {
  title "Pixel Editor - Text"
  icon $scriptdirCube.ico
  size -1 -1 220 107
  option map
  edit "", 1, 5 5 210 11
  text "Font:", 2, 5 22 19 11
  combo 3, 41 20 66 150, drop sort
  text "Font size:", 4, 5 40 33 11
  combo 5, 41 38 66 150, drop
  text "Text colour:", 6, 113 22 41 11
  combo 7, 180 20 35 150, drop
  text "Background colour:", 8, 113 40 65 11
  combo 9, 180 38 35 150, drop
  check "Bold", 10, 5 57 29 11
  check "Italic", 11, 65 57 30 11
  check "Underline", 12, 125 57 46 11
  check "Insert into existing image", 13, 5 71 91 11
  button "Create", 14, 6 86 104 16, disable default
  button "Cancel", 15, 111 86 104 16, cancel
}

on *:dialog:pe.text:init:0: {
  drawdot @Pixel
  did -a pe.text 1 %pixed.text
  did $iif(%pixed.text == $null,-b,-e) pe.text 14
  didtok pe.text 3 44 Fixedsys
  noop $findfile(C:\Windows\Fonts,*.ttf,0,did -a pe.text 3 $gettok($nopath($1-),-2--,46))
  if (%pixed.font == $null) %pixed.font = Fixedsys
  if ($didwm(3,%pixed.font)) did -c pe.text 3 $v1
  else did -ca pe.text 3 %pixed.font
  didtok pe.text 5 32 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
  if ($didwm(5,%pixed.fontsize)) did -c pe.text 5 $v1
  else {
    did -ca pe.text 5 1
    %pixed.fontsize = $did(pe.text,5)
  }
  didtok pe.text 7,9 32 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98
  did -i pe.text 9 1 none
  if (%pixed.textcolour !isnum 0-98) %pixed.textcolour = 1
  if ($didwm(7,%pixed.textcolour)) did -c pe.text 7 $v1
  else did -c pe.text 7 2
  if (%pixed.bgcolour !isnum 0-98) %pixed.bgcolour = none
  if ($didwm(7,%pixed.bgcolour)) did -c pe.text 9 $v1
  else did -c pe.text 9 1
  if (%pixed.bold) did -c pe.text 10
  if (%pixed.italic) did -c pe.text 11
  if (%pixed.underline) did -c pe.text 12
  if (%pixed.inserttext == $null) %pixed.inserttext = 1
  if (%pixed.inserttext) did -c pe.text 13
}

on *:dialog:pe.text:edit:1: {
  %pixed.text = $did(1)
  did $iif(%pixed.text == $null,-b,-e) pe.text 14
}

on *:dialog:pe.text:sclick:3:%pixed.font = $did(3)

on *:dialog:pe.text:sclick:5:%pixed.fontsize = $did(5)

on *:dialog:pe.text:sclick:7:%pixed.textcolour = $did(7)

on *:dialog:pe.text:sclick:9:%pixed.bgcolour = $did(9)

on *:dialog:pe.text:sclick:10:%pixed.bold = $did(10).state

on *:dialog:pe.text:sclick:11:%pixed.italic = $did(11).state

on *:dialog:pe.text:sclick:12:%pixed.underline = $did(12).state

on *:dialog:pe.text:sclick:13:%pixed.inserttext = $did(13).state

on *:dialog:pe.text:sclick:14: {
  set -l %c $+($iif(%pixed.bold,$chr(2)),$iif(%pixed.italic,$chr(29)),$iif(%pixed.underline,$chr(31)))
  if ($width(%c $+ %pixed.text,%pixed.font,%pixed.fontsize,p) <= 256) set -l %w $v1
  else set -l %w 256
  if ($height(%c $+ %pixed.text,%pixed.font,%pixed.fontsize,p) <= 256) set -l %h $v1
  else set -l %h 256
  pe.clearredo
  if (%pixed.inserttext) {
    clear -n @pe.tool
    tokenize 32 $calc(%w *%pixed.size) $calc(%h *%pixed.size)
    drawsize @pe.tool $1-
    drawline -nr @pe.tool %pe.frame 1 $pe.grid(%w,%h)
    clear -n @pe.temp
    drawsize @pe.temp %w %h
    drawtext -nrpb @pe.temp $color(%pixed.textcolour) $iif(%pixed.bgcolour !isnum 0-98,%pe.transparent,$color($v1)) $qt(%pixed.font) %pixed.fontsize 0 0 %c $+ %pixed.text
    set -l %x 0
    set -l %a 0
    set -l %y
    set -l %b
    while (%x < %w) {
      %y = 0
      %b = 0
      while (%y < %h) {
        drawrect -nrf @pe.tool $iif($getdot(@pe.temp,%x,%y) == %pe.transparent,$v1,$pe.match($v1)) 1 %a %b %pe.rectangle
        inc %y
        inc %b %pixed.size
      }
      inc %x
      inc %a %pixed.size
    }
    drawline -rn @pe.mirror %pe.frame 1 %pe.grid
    pe.mirror
    drawcopy -nt @pe.tool %pe.transparent 0 0 $calc(1+%w *%pixed.size) $calc(1+%h *%pixed.size) @Pixel 200 0
    drawrect -rn @pixel %pe.3dlight 1 199 -1 $calc(1+%w *%pixed.size) $calc(1+%h *%pixed.size)
    %pe.copy = 0 0 %w %h
    pe.tool select
    drawdot @Pixel
  }
  else {
    pe.clearundo
    %pixed.width = %w
    %pixed.height = %h
    pe.checksize
    %pe.rectangle = %pixed.size - 1
    %pe.rectangle = %pe.rectangle %pe.rectangle
    pe.update
    titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
    pe.tool select
    clear -n @pe.mirror
    drawsize @pe.mirror %pe.width %pe.height
    clear -n @pe.temp
    drawsize @pe.temp %w %h
    drawtext -nrpb @pe.temp $color(%pixed.textcolour) $iif(%pixed.bgcolour !isnum 0-98,%pe.background,$color($v1)) $qt(%pixed.font) %pixed.fontsize 0 0 %c $+ %pixed.text
    set -l %x 0
    set -l %a 0
    set -l %y
    set -l %b
    while (%x < %w) {
      %y = 0
      %b = 0
      while (%y < %h) {
        drawrect -nrf @pe.mirror $getdot(@pe.temp,%x,%y) 1 %a %b %pe.rectangle
        inc %y
        inc %b %pixed.size
      }
      inc %x
      inc %a %pixed.size
    }
    drawline -rn @pe.mirror %pe.frame 1 %pe.grid
    window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
    pe.mirror
  }
  dialog -c pe.text
}

alias -l pe.mouse {
  %pe.mx = $mouse.x
  %pe.my = $mouse.y
  %pe.y = $floor($calc(%pe.my /%pixed.size))
  %pe.ry = %pe.y * %pixed.size
  if (%pe.mx >= 200) {
    %pe.x = $floor($calc((%pe.mx -200)/%pixed.size))
    %pe.rx = %pe.x * %pixed.size
    if (%pe.tool == select) {
      tokenize 32 $sorttok(%pe.ax %pe.x,32,n) $sorttok(%pe.ay %pe.y,32,n)
      %pe.select = $1 $3 $calc(1+$2 -$1) $calc(1+$4 -$3)
      tokenize 32 %pe.select
      set -l %tip pe.imagetip $3 x $4
      drawline -rn @pe.mirror %pe.frame 1 %pe.grid
      drawrect -crn @pe.mirror %pe.3dlight 1 $calc($1 *%pixed.size -1) $calc($2 *%pixed.size -1) $calc(1+$3 *%pixed.size) $calc(1+$4 *%pixed.size)
    }
    elseif (%pe.tool == selectmove) {
      tokenize 32 %pe.copy
      %pe.copy = $calc(%pe.x -%pe.offsetx) $calc(%pe.y -%pe.offsety) $3-4
      set -l %tip pe.imagetip X: $1 Y: $2 WH: $3 x $4
    }
    elseif (%pe.tool == pencil) {
      if (%pe.colour != $getdot(@pe.mirror,%pe.rx,%pe.ry)) pe.drawdot $v1 $v2 %pe.x %pe.y
      set -l %tip pe.imagetip X: %pe.x Y: %pe.y
    }
    elseif (%pe.tool == line) {
      drawrect -frn @pe.tool %pe.transparent 1 0 0 %pixed.width %pixed.height
      drawdot -rn @pe.tool %pe.colour 1 %pe.ax %pe.ay
      drawline -rn @pe.tool %pe.colour 1 %pe.x %pe.y %pe.ax %pe.ay
      set -l %tip pe.imagetip X: %pe.x Y: %pe.y
    }
    elseif (%pixed.tool == replace colour) {
      set -l %c $hget(pe.mirc,$getdot(@pe.mirror,%pe.rx,%pe.ry))
      if (%pe.replace isnum) set -l %tip pe.imagetip $+(Replace colour,$v1 $v1 with colour,%c %c,...)
      else set -l %tip pe.imagetip $+(Replace colour,%c %c,...)
    }
    elseif (%pixed.tool == colour picker) {
      set -l %c $getdot(@pe.mirror,%pe.rx,%pe.ry)
      set -l %tip pe.imagetip mIRC: $hget(pe.mirc,%c) RGB: $rgb(%c)
    }
    elseif ($istok(rectangle|filled rectangle|focus rectangle,%pe.tool,124)) {
      drawrect -frn @pe.tool %pe.transparent 1 0 0 %pixed.width %pixed.height
      drawdot -rn @pe.tool %pe.colour 1 %pe.ax %pe.ay
      tokenize 32 $sorttok(%pe.ax %pe.x,32,n) $sorttok(%pe.ay %pe.y,32,n)
      tokenize 32 $1 $3 $calc(1+$2 -$1) $calc(1+$4 -$3)
      set -l %tip pe.imagetip X: %pe.x Y: %pe.y WH: $3 x $4
      drawrect %pe.parms @pe.tool %pe.colour 1 $1-
    }
    elseif ($istok(ellipse|filled ellipse,%pe.tool,124)) {
      drawrect -frn @pe.tool %pe.transparent 1 0 0 %pixed.width %pixed.height
      tokenize 32 $sorttok(%pe.ax %pe.x,32,n) $sorttok(%pe.ay %pe.y,32,n)
      tokenize 32 $1 $3 $calc(1+$2 -$1) $calc(1+$4 -$3)
      set -l %tip pe.imagetip X: %pe.x Y: %pe.y WH: $3 x $4
      drawrect %pe.parms @pe.tool %pe.colour 1 $1-
    }
  }
  else {
    drawrect -nrf @Pixel %pe.face 1 0 0 199 %pe.height
    drawline -nr @Pixel %pe.frame 1 199 0 199 %pe.height
    %pe.x = 0
    %pe.rx = 0
    if (%pe.mx isnum 3-194) && (%pe.my isnum 3-162) {
      drawcopy -n @pe.cache 0 0 194 228 @Pixel 2 2
      if ($hget(pe.mirc,$getdot(@Pixel,%pe.mx,%pe.my)) isnum 0-98) {
        set -l %c $v1
        if (%pixed.tool == replace colour) {
          if (%pe.replace isnum) set -l %tip pe.paneltip $+(Replace colour,$v1 $v1 with colour,%c %c,...)
          else set -l %tip pe.paneltip $+(Replace colour,%c %c,...)
        }
        else set -l %tip pe.paneltip mIRC: %c RGB: $rgb($getdot(@Pixel,%pe.mx,%pe.my))
      }
    }
    elseif (%pe.mx isnum 5-194) && (%pe.my isnum 169-231) {
      set -l %a $int($calc((%pe.mx -5)/32))
      set -l %b $int($calc((%pe.my -169)/32))
      if ($inrect(%pe.mx,%pe.my,$calc(%a *32+4),$calc(%b *32+168),30,30)) set -l %tip pe.paneltip $gettok($pe.tools,$calc((1+%a)+6*%b),124)
    }
  }
  drawcopy -n @pe.mirror 0 0 %pe.width %pe.height @Pixel 200 0
  if (%pe.copy) pe.copy $v1
  elseif ($istok(line|rectangle|filled rectangle|ellipse|filled ellipse|focus rectangle,%pe.tool,124)) {
    drawcopy -nt @pe.tool %pe.transparent 0 0 %pixed.width %pixed.height @Pixel 200 0 %pe.width %pe.height
    drawline -rn @Pixel %pe.frame 1 %pe.altgrid
  }
  pe.panel
  if (%tip) $v1
  drawdot @Pixel
}

alias -l pe.finish {
  if (%pe.tool == line) {
    tokenize 32 $sorttok(%pe.ax %pe.x,32,n) $sorttok(%pe.ay %pe.y,32,n)
    pe.savearea $1 $3 $calc(1+$2 -$1) $calc(1+$4 -$3)
    drawrect -frn @pe.tool %pe.transparent 1 0 0 %pixed.width %pixed.height
    drawdot -rn @pe.tool %pe.colour 1 %pe.ax %pe.ay
    drawline -rn @pe.tool %pe.colour 1 %pe.x %pe.y %pe.ax %pe.ay
    drawcopy -nt @pe.tool %pe.transparent 0 0 %pixed.width %pixed.height @pe.mirror 0 0 %pe.width %pe.height
    drawline -rn @pe.mirror %pe.frame 1 %pe.grid
  }
  elseif ($istok(rectangle|filled rectangle|focus rectangle,%pe.tool,124)) {
    drawrect -frn @pe.tool %pe.transparent 1 0 0 %pixed.width %pixed.height
    drawdot -rn @pe.tool %pe.colour 1 %pe.ax %pe.ay
    tokenize 32 $sorttok(%pe.ax %pe.x,32,n) $sorttok(%pe.ay %pe.y,32,n)
    tokenize 32 $1 $3 $calc(1+$2 -$1) $calc(1+$4 -$3)
    pe.savearea $1-
    drawrect %pe.parms @pe.tool %pe.colour 1 $1-
    drawcopy -nt @pe.tool %pe.transparent 0 0 %pixed.width %pixed.height @pe.mirror 0 0 %pe.width %pe.height
    drawline -rn @pe.mirror %pe.frame 1 %pe.grid
  }
  elseif ($istok(ellipse|filled ellipse,%pe.tool,124)) {
    drawrect -frn @pe.tool %pe.transparent 1 0 0 %pixed.width %pixed.height
    tokenize 32 $sorttok(%pe.ax %pe.x,32,n) $sorttok(%pe.ay %pe.y,32,n)
    tokenize 32 $1 $3 $calc(1+$2 -$1) $calc(1+$4 -$3)
    pe.savearea $1-
    drawrect %pe.parms @pe.tool %pe.colour 1 $1-
    drawcopy -nt @pe.tool %pe.transparent 0 0 %pixed.width %pixed.height @pe.mirror 0 0 %pe.width %pe.height
    drawline -rn @pe.mirror %pe.frame 1 %pe.grid
  }
  unset %pe.tool %pe.parms
  drawcopy -n @pe.mirror 0 0 %pe.width %pe.height @Pixel 200 0
  if (%pe.copy) pe.copy $v1
  pe.panel
  drawdot @Pixel
}

;DEL
on *:keydown:@Pixel:46: {
  if (%pe.copy) {
    unset %pe.copy
    pe.mirror
    drawdot @Pixel
  }
  elseif (!%pe.tool) && (%pe.select) {
    tokenize 32 $v1
    unset %pe.select
    pe.savearea $v1
    pe.clearredo
    drawrect -fn @pe.mirror %pe.background 1 $calc($1 *%pixed.size) $calc($2 *%pixed.size) $calc($3 *%pixed.size) $calc($4 *%pixed.size)
    drawline -nr @pe.mirror %pe.frame 1 %pe.grid
    pe.mirror
    drawdot @Pixel
  }
  else beep 1
}

;CTRL+C
on *:keydown:@Pixel:67: {
  if (%pe.ctrl) {
    if (!%pe.tool) && (!%pe.copy) && (%pe.select) {
      pe.getarea $v1
      hadd -b pe.cache copydata &
      hadd pe.cache copy %pe.select
    }
    else beep 1
  }
}

;CTRL+X
on *:keydown:@Pixel:88: {
  if (%pe.ctrl) {
    if (!%pe.tool) && (!%pe.copy) && (%pe.select) {
      tokenize 32 $v1
      pe.savearea $v1
      pe.clearredo
      hadd -b pe.cache copydata &
      hadd pe.cache copy %pe.select
      drawrect -fn @pe.mirror %pe.background 1 $calc($1 *%pixed.size) $calc($2 *%pixed.size) $calc($3 *%pixed.size) $calc($4 *%pixed.size)
      drawline -nr @pe.mirror %pe.frame 1 %pe.grid
      pe.mirror
      drawdot @Pixel
    }
    else beep 1
  }
}

;CTRL+V
on *:keydown:@Pixel:86: {
  if (%pe.ctrl) {
    if (!%pe.tool) && ($hget(pe.cache,copydata,&)) && ($hget(pe.cache,copy)) {
      tokenize 32 $v1
      pe.clearredo
      set -l %w $3 * %pixed.size
      set -l %h $4 * %pixed.size
      clear -n @pe.tool
      drawsize @pe.tool %w %h
      drawline -rn @pe.tool %pe.frame 1 $pe.grid($3,$4)
      %y = 0
      set -l %l 1
      while ($bvar(&,%l,$3)) {
        %x = 0
        pe.pasteline $v1
        inc %y %pixed.size
        inc %l $3
      }
      drawline -rn @pe.mirror %pe.frame 1 %pe.grid
      pe.mirror
      if (%pe.select) tokenize 32 $gettok($v1,1-2,32) $3-4
      drawcopy -n @pe.tool 0 0 $calc(1+$3 *%pixed.size) $calc(1+$4 *%pixed.size) @Pixel $calc(200+$1 *%pixed.size) $calc($2 *%pixed.size)
      drawrect -rn @pixel %pe.3dlight 1 $calc(199+$1 *%pixed.size) $calc($2 *%pixed.size -1) $calc(1+$3 *%pixed.size) $calc(1+$4 *%pixed.size)
      %pe.copy = $1-
      pe.tool select
      unset %pe.select %y %x
      drawdot @Pixel
    }
    else beep 1
  }
}

alias -l pe.pasteline pe.pastedot $*

alias -l pe.pastedot drawrect -nf @pe.tool $1 1 %x %y %pe.rectangle | inc %x %pixed.size

;Enter
on *:keydown:@Pixel:13:if (%pe.copy) pe.finishcopy

alias -l pe.finishcopy {
  tokenize 32 %pe.copy
  pe.savearea $1-
  unset %pe.copy
  drawcopy -nt @pe.tool %pe.transparent 0 0 $calc($3 *%pixed.size) $calc($4 *%pixed.size) @pe.mirror $calc($1 *%pixed.size) $calc($2 *%pixed.size)
  pe.mirror
  drawdot @Pixel
}

alias -l pe.savearea {
  pe.tip Processing...
  if ($1 < 0) tokenize 32 0 $2 $calc($3 +-$1) $4
  if ($calc($1 +$3) > %pixed.width) tokenize 32 $1-2 $calc($v2 -$1) $4
  if ($2 < 0) tokenize 32 $1 0 $3 $calc($4 +-$2)
  if ($calc($2 +$4) > %pixed.height) tokenize 32 $1-3 $calc($v2 -$2)
  pe.getarea $1-
  set -l %h $iif($show,undo,redo) $+ $sha1($ticksqpc)
  if ($show) iline @pe.undo 1 .pe.drawarea $1- %h
  else iline -l @pe.undo 1 pe.drawarea $1- %h
  hadd -b pe.cache %h &
}

alias -l pe.getarea {
  %s = $1 * %pixed.size
  %y = $2 * %pixed.size
  set -l %tokens $str(x $chr(32),$calc($3 -1))
  tokenize 46 $str(x.,$4)
  pe.getline $* %tokens
  unset %x %y %s
}

alias -l pe.getline %x = %s | pe.getdot $* | inc %y %pixed.size

alias -l pe.getdot bset & -1 $hget(pe.mirc,$getdot(@pe.mirror,%x,%y)) | inc %x %pixed.size

alias -l pe.drawarea {
  pe.tip Processing...
  if ($show) pe.savearea $1-4
  else .pe.savearea $1-4
  hdel -w pe.cache $5 $hget(pe.cache,$5,&)
  set -l %s $1 * %pixed.size
  %y = $2 * %pixed.size
  set -l %p 1
  while ($bvar(&,%p,$3)) {
    %x = %s
    pe.drawline $v1
    inc %y %pixed.size
    inc %p $3
  }
  unset %x %y
}

alias -l pe.drawline pe.draw $*

alias -l pe.draw drawrect -nf @pe.mirror $1 1 %x %y %pe.rectangle | inc %x %pixed.size

;CTRL+H
on *:keydown:@Pixel:72: {
  if (%pe.ctrl) {
    pe.horflip
    pe.clearredo
  }
}

alias -l pe.horflip {
  if (!%pe.tool) {
    pe.tip Processing...
    clear -n @pe.temp
    if (%pe.copy) {
      tokenize 32 $v1
      set -l %w $3 * %pixed.size
      set -l %h $4 * %pixed.size
      drawsize @pe.temp %w %h
      drawcopy -n @pe.tool 0 0 %w %h @pe.temp 0 0
      set -l %x
      set -l %y %h - %pixed.size
      set -l %a
      set -l %s %w - %pixed.size
      while (%y >= 0) {
        %x = %s
        %a = 0
        while (%x >= 0) {
          drawrect -rnf @pe.tool $getdot(@pe.temp,%a,%y) 1 %x %y %pe.rectangle
          dec %x %pixed.size
          inc %a %pixed.size
        }
        dec %y %pixed.size
      }
      %x = $1 * %pixed.size
      %y = $2 * %pixed.size
      pe.mirror
      pe.copy %pe.copy
      drawdot @Pixel
    }
    else {
      if ($show) iline @pe.undo 1 .pe.horflip
      else iline -l @pe.undo 1 pe.horflip
      drawsize @pe.temp %pe.width %pe.height
      drawcopy -n @pe.mirror 0 0 %pe.width %pe.height @pe.temp 0 0
      set -l %y %pe.height - %pixed.size
      set -l %x
      set -l %a
      set -l %s %pe.width - %pixed.size
      while (%y >= 0) {
        %x = %s
        %a = 0
        while (%x >= 0) {
          drawrect -rnf @pe.mirror $getdot(@pe.temp,%a,%y) 1 %x %y %pe.rectangle
          dec %x %pixed.size
          inc %a %pixed.size
        }
        dec %y %pixed.size
      }
      pe.mirror
      drawdot @Pixel
    }
  }
  else beep 1
}

alias -l pe.verflip {
  if (!%pe.tool) {
    pe.tip Processing...
    clear -n @pe.temp
    if (%pe.copy) {
      tokenize 32 $v1
      set -l %w $3 * %pixed.size
      set -l %h $4 * %pixed.size
      drawsize @pe.temp %w %h
      drawcopy -n @pe.tool 0 0 %w %h @pe.temp 0 0
      set -l %x %w - %pixed.size
      set -l %y
      set -l %a
      set -l %s %h - %pixed.size
      while (%x >= 0) {
        %y = %s
        %a = 0
        while (%y >= 0) {
          drawrect -rnf @pe.tool $getdot(@pe.temp,%x,%a) 1 %x %y %pe.rectangle
          dec %y %pixed.size
          inc %a %pixed.size
        }
        dec %x %pixed.size
      }
      %x = $1 * %pixed.size
      %y = $2 * %pixed.size
      pe.mirror
      pe.copy %pe.copy
      drawdot @Pixel
    }
    else {
      if ($show) iline @pe.undo 1 .pe.horflip
      else iline -l @pe.undo 1 pe.horflip
      drawsize @pe.temp %pe.width %pe.height
      drawcopy -n @pe.mirror 0 0 %pe.width %pe.height @pe.temp 0 0
      set -l %x %pe.width - %pixed.size
      set -l %y
      set -l %a
      set -l %s %pe.height - %pixed.size
      while (%x >= 0) {
        %y = %s
        %a = 0
        while (%y >= 0) {
          drawrect -rnf @pe.mirror $getdot(@pe.temp,%x,%a) 1 %x %y %pe.rectangle
          dec %y %pixed.size
          inc %a %pixed.size
        }
        dec %x %pixed.size
      }
      pe.mirror
      drawdot @Pixel
    }
  }
  else beep 1
}

;CTRL+R
on *:keydown:@Pixel:82: {
  if (%pe.ctrl) {
    pe.rotate 90
    pe.clearredo
  }
}

alias -l pe.rotate {
  if (!%pe.tool) {
    if (%pe.copy) {
      tokenize 32 $v1 $1
      set -l %w $3 * %pixed.size
      set -l %h $4 * %pixed.size
      set -l %m $max(%w,%h)
      drawsize @pe.tool %m %m
      drawrot -n @pe.tool $5 0 0 $calc($3 *%pixed.size -1) $calc($4 *%pixed.size -1)
      if ($5 != 180) {
        %pe.copy = $1-2 $4 $3
        tokenize 32 %pe.copy
      }
      drawline -rn @pe.tool %pe.frame 1 $pe.grid($3,$4)
      pe.mirror
      pe.copy %pe.copy
    }
    else {
      set -l %o $iif($1 > 0,- $+ $1,$abs($1))
      if ($show) iline @pe.undo 1 .pe.rotate %o
      else iline -l @pe.undo 1 pe.rotate %o
      set -l %m $max(%pe.width,%pe.height)
      drawsize @pe.mirror %m %m
      drawrot -n @pe.mirror $1 0 0 $calc(%pe.width -1) $calc(%pe.height -1)
      if ($1 != 180) {
        tokenize 32 %pixed.width %pixed.height
        %pixed.width = $2
        %pixed.height = $1
        pe.update
        titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
        window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
      }
      pe.mirror
    }
    drawdot @Pixel
  }
}

alias -l pe.resize {
  if (!%pe.tool) {
    if (%pe.copy) {
      set -l %m $1
      tokenize 32 $v1
      set -l %w $round($calc($3 *%m),0)
      set -l %h $round($calc($4 *%m),0)
      if (%w > 256) || (%h > 256) return $input(Cannot resize the picture as width and/or height would exceed 256 pixels.,owu,Pixel Editor)
      if (%w < 1) || (%h < 1) return $input(Cannot resize the picture as width and/or height would be below 1 pixel.,owu,Pixel Editor)
      pe.tip Processing...
      drawsize @pe.temp $max($3,%w) $max($4,%h)
      set -l %x
      set -l %a
      set -l %y 0
      set -l %b 0
      set -l %c
      while (%b < $4) {
        %x = 0
        %a = 0
        while (%a < $3) {
          drawdot -rn @pe.temp $getdot(@pe.tool,%x,%y) 1 %a %b
          inc %x %pixed.size
          inc %a
        }
        inc %y %pixed.size
        inc %b
      }
      drawcopy $iif(%pixed.highquality,-nm,-n) @pe.temp 0 0 $3-4 @pe.temp 0 0 %w %h
      %pe.copy = $1-2 %w %h
      clear -n @pe.tool
      drawsize @pe.tool $calc(%w *%pixed.size) $calc(%h *%pixed.size)
      drawline -rn @pe.tool %pe.frame 1 $pe.grid(%w,%h)
      %y = 0
      %b = 0
      while (%b < %h) {
        %x = 0
        %a = 0
        while (%a < %w) {
          drawrect -rnf @pe.tool $pe.match($getdot(@pe.temp,%a,%b)) 1 %x %y %pe.rectangle
          inc %x %pixed.size
          inc %a
        }
        inc %y %pixed.size
        inc %b
      }
      pe.tool select
      pe.mirror
      pe.copy %pe.copy
    }
    else {
      set -l %w $round($calc(%pixed.width *$1),0)
      set -l %h $round($calc(%pixed.height *$1),0)
      if (%w > 256) || (%h > 256) return $input(Cannot resize the picture as width and/or height would exceed 256 pixels.,owu,Pixel Editor)
      if (%w < 1) || (%h < 1) return $input(Cannot resize the picture as width and/or height would be below 1 pixel.,owu,Pixel Editor)
      pe.tip Processing...
      drawsize @pe.temp $max(%pixed.width,%w) $max(%pixed.height,%h)
      set -l %x
      set -l %a
      set -l %y 0
      set -l %b 0
      set -l %c
      while (%b < %pixed.height) {
        %x = 0
        %a = 0
        while (%a < %pixed.width) {
          %c = $getdot(@pe.mirror,%x,%y)
          drawdot -rn @pe.temp %c 1 %a %b
          bset & -1 $hget(pe.mirc,%c)
          inc %x %pixed.size
          inc %a
        }
        inc %y %pixed.size
        inc %b
      }
      set -l %hash undo $+ $sha1($ticksqpc)
      hadd -b pe.cache %hash &
      if ($show) iline @pe.undo 1 .pe.undoresize $1 %pixed.width %pixed.height %hash
      else iline -l @pe.undo 1 pe.undoresize $1 %pixed.width %pixed.height %hash
      drawcopy $iif(%pixed.highquality,-nm,-n) @pe.temp 0 0 %pixed.width %pixed.height @pe.temp 0 0 %w %h
      %pixed.width = %w
      %pixed.height = %h
      pe.checksize
      pe.update
      titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
      clear -n @pe.mirror
      drawsize @pe.mirror %pe.width %pe.height
      drawline -nr @pe.mirror %pe.frame 1 %pe.grid
      %y = 0
      %b = 0
      while (%b < %pixed.height) {
        %x = 0
        %a = 0
        while (%a < %pixed.width) {
          drawrect -rnf @pe.mirror $pe.match($getdot(@pe.temp,%a,%b)) 1 %x %y %pe.rectangle
          inc %x %pixed.size
          inc %a
        }
        inc %y %pixed.size
        inc %b
      }
      window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
      pe.mirror
    }
    drawdot @Pixel
  }
  else beep 1
}

alias -l pe.undoresize {
  if ($hget(pe.cache,$4,&)) {
    hdel -w pe.cache $4
    if ($show) iline @pe.undo 1 .pe.resize $1
    else iline -l @pe.undo 1 pe.resize $1
    %pixed.width = $2
    %pixed.height = $3
    pe.update
    titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
    clear -n @pe.mirror
    drawsize @pe.mirror %pe.width %pe.height
    drawline -nr @pe.mirror %pe.frame 1 %pe.grid
    %y = 0
    set -l %p 1
    while ($bvar(&,%p,$2)) {
      %x = 0
      pe.drawline $v1
      inc %y %pixed.size
      inc %p $2
    }
    unset %x %y
    window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
    pe.mirror
    drawdot @Pixel
  }
  else beep 1
}

alias -l pe.movecopy {
  tokenize 32 %pe.copy $1-
  %pe.copy = $calc($1 +$5) $calc($2 +$6) $3-4
  pe.mirror
  pe.copy %pe.copy
  drawdot @Pixel
}

alias -l pe.checksize {
  if ($ceil($min($calc(800/%pixed.width),$calc(600/%pixed.height))) > 3) %pixed.size = $v1
  else %pixed.size = 3
  while ($calc(%pixed.height *%pixed.size) < 230) inc %pixed.size
  %pe.rectangle = %pixed.size - 1
  %pe.rectangle = %pe.rectangle %pe.rectangle
}

alias -l pe.update {
  %pe.width = %pixed.width * %pixed.size
  %pe.height = %pixed.height * %pixed.size
  %pe.grid = $pe.grid(%pixed.width,%pixed.height)
  %pe.altgrid = $pe.grid(%pixed.width,%pixed.height,200)
}

alias -l pe.getcolumn {
  set -l %y %pe.height - %pixed.size
  set -l %l
  while (%y >= 0) {
    %l = $getdot(@pe.mirror,$1,%y) %l
    dec %y %pixed.size
  }
  return %l
}

alias -l pe.drawcolumn {
  set -l %y 0
  while ($2 isnum) {
    drawrect -rnf @pe.mirror $2 1 $1 %y %pe.rectangle
    tokenize 32 $1 $3-
    inc %y %pixed.size
  }
}

;LEFT
on *:keydown:@Pixel:37: {
  if (%pe.copy) pe.movecopy $iif((%pe.ctrl) || (%pe.shift),-10,-1) 0
  elseif (%pe.ctrl) { pe.removeleft | pe.clearredo }
  elseif (%pe.shift) { pe.addleft | pe.clearredo }
}

alias -l pe.removeleft {
  if (%pixed.width > 1) {
    if ($show) iline @pe.undo 1 .pe.addleft $pe.getcolumn(0)
    else iline -l @pe.undo 1 pe.addleft $pe.getcolumn(0)
    drawscroll @pe.mirror - $+ %pixed.size 0 0 0 %pe.width %pe.height
    dec %pixed.width
    pe.update
    titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
    window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
    pe.mirror
    drawdot @Pixel
  }
  else beep 1
}

alias -l pe.addleft {
  if (%pixed.height < 256) {
    if ($show) iline @pe.undo 1 .pe.removeleft
    else iline -l @pe.undo 1 pe.removeleft
    inc %pixed.width
    pe.update
    titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
    drawsize @pe.mirror %pe.width %pe.height
    drawscroll @pe.mirror %pixed.size 0 0 0 %pe.width %pe.height
    if ($1-) pe.drawcolumn 0 $1-
    else drawrect -nf @pe.mirror %pe.background 1 0 0 %pixed.size %pe.height
    drawline -nr @pe.mirror %pe.frame 1 %pe.grid
    window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
    pe.mirror
    drawdot @Pixel
  }
  else beep 1
}

;RIGHT
on *:keydown:@Pixel:39: {
  if (%pe.copy) pe.movecopy $iif((%pe.ctrl) || (%pe.shift),10,1) 0
  elseif (%pe.ctrl) { pe.removeright | pe.clearredo }
  elseif (%pe.shift) { pe.addright | pe.clearredo }
}

alias -l pe.removeright {
  if (%pixed.width > 1) {
    set -l %c $pe.getcolumn($calc(%pe.width -%pixed.size))
    if ($show) iline @pe.undo 1 .pe.addright %c
    else iline -l @pe.undo 1 pe.addright %c
    dec %pixed.width
    pe.update
    titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
    window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
  }
  else beep 1
}

alias -l pe.addright {
  if (%pixed.height < 256) {
    if ($show) iline @pe.undo 1 .pe.removeright
    else iline -l @pe.undo 1 pe.removeright
    inc %pixed.width
    pe.update
    titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
    drawsize @pe.mirror %pe.width %pe.height
    if ($1-) pe.drawcolumn $calc(%pe.width -%pixed.size) $1-
    else drawrect -nf @pe.mirror %pe.background 1 $calc(%pe.width -%pixed.size) 0 %pixed.size %pe.height
    drawline -nr @pe.mirror %pe.frame 1 %pe.grid
    window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
    pe.mirror
    drawdot @Pixel
  }
  else beep 1
}

alias -l pe.getrow {
  set -l %x %pe.width - %pixed.size
  set -l %l
  while (%x >= 0) {
    %l = $getdot(@pe.mirror,%x,$1) %l
    dec %x %pixed.size
  }
  return %l
}

alias -l pe.drawrow {
  set -l %x 0
  while ($2 isnum) {
    drawrect -rnf @pe.mirror $2 1 %x $1 %pe.rectangle
    tokenize 32 $1 $3-
    inc %x %pixed.size
  }
}

;UP
on *:keydown:@Pixel:38: {
  if (%pe.copy) pe.movecopy 0 $iif((%pe.ctrl) || (%pe.shift),-10,-1)
  elseif (%pe.ctrl) { pe.removetop | pe.clearredo }
  elseif (%pe.shift) { pe.addtop | pe.clearredo }
}

alias -l pe.removetop {
  if (%pixed.height > 1) {
    if ($show) iline @pe.undo 1 .pe.addtop $pe.getrow(0)
    else iline -l @pe.undo 1 pe.addtop $pe.getrow(0)
    drawscroll @pe.mirror 0 - $+ %pixed.size 0 0 %pe.width %pe.height
    dec %pixed.height
    pe.update
    titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
    window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
    pe.mirror
    drawdot @Pixel
  }
  else beep 1
}

alias -l pe.addtop {
  if (%pixed.height < 256) {
    if ($show) iline @pe.undo 1 .pe.removetop
    else iline -l @pe.undo 1 pe.removetop
    inc %pixed.height
    pe.update
    titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
    drawsize @pe.mirror %pe.width %pe.height
    drawscroll @pe.mirror 0 %pixed.size 0 0 %pe.width %pe.height
    if ($1-) pe.drawrow 0 $1-
    else drawrect -nf @pe.mirror %pe.background 1 0 0 %pe.width %pixed.size
    drawline -nr @pe.mirror %pe.frame 1 %pe.grid
    window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
    pe.mirror
    drawdot @Pixel
  }
  else beep 1
}

;DOWN
on *:keydown:@Pixel:40: {
  if (%pe.copy) pe.movecopy 0 $iif((%pe.ctrl) || (%pe.shift),10,1)
  elseif (%pe.ctrl) { pe.removebottom | pe.clearredo }
  elseif (%pe.shift) { pe.addbottom | pe.clearredo }
}

alias -l pe.removebottom {
  if (%pixed.height > 1) {
    set -l %r $pe.getrow($calc(%pe.height -%pixed.size))
    if ($show) iline @pe.undo 1 .pe.addbottom %r
    else iline -l @pe.undo 1 pe.addbottom %r
    dec %pixed.height
    pe.update
    titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
    window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
  }
  else beep 1
}

alias -l pe.addbottom {
  if (%pixed.height < 256) {
    if ($show) iline @pe.undo 1 .pe.removebottom
    else iline -l @pe.undo 1 pe.removebottom
    inc %pixed.height
    pe.update
    titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
    drawsize @pe.mirror %pe.width %pe.height
    if ($1-) pe.drawrow $calc(%pe.height -%pixed.size) $1-
    else drawrect -nf @pe.mirror %pe.background 1 0 $calc(%pe.height -%pixed.size) %pe.width %pixed.size
    drawline -nr @pe.mirror %pe.frame 1 %pe.grid
    window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
    pe.mirror
    drawdot @Pixel
  }
  else beep 1
}

;CTRL+I
on *:keydown:@Pixel:73:if (%pe.ctrl) pe.import

alias -l pe.import {
  if ($sfile($iif($isdir(%pixed.lastimage),%pixed.lastimage,$mircdir) $+ *.bmp;*.png;*.jpg;*.jpeg;*.gif,Choose an image file to import,Select)) {
    set -u %pe.import image $v1
    noop $dialog(pe.import,pe.import,-3)
  }
}

dialog -l pe.import {
  title "Pixel Editor - Import"
  icon $scriptdirCube.ico
  size -1 -1 225 177
  option map
  button "Import", 2, 101 161 60 14, default
  button "Close", 3, 162 161 60 14, ok
  check "Insert into existing image", 10, 4 145 93 11
  text "Transparent colour:", 11, 112 146 65 11, right
  combo 12, 181 145 40 150, drop
  tab "Image file", 100, 4 2 218 141
  edit "", 101, 12 25 200 11, tab 100 autohs read
  text "Supported formats: BMP, PNG, GIF and JPG", 102, 12 40 144 11, tab 100
  button "Browse", 103, 162 38 50 13, tab 100
  text "Width:", 104, 12 55 24 11, tab 100
  edit "", 105, 37 54 30 11, tab 100 center limit 4
  text "Height:", 106, 74 55 24 11, tab 100
  edit "", 107, 100 54 30 11, tab 100 center limit 4
  scroll "", 108, 137 53 74 12, tab 100 horizontal range 1 100
  check "Maintain aspect ratio", 109, 12 70 81 11, tab 100
  check "High quality stretch mode", 110, 12 82 95 11, tab 100
  check "Triple width multiplier", 111, 12 94 79 11, tab 100
  link "Help", 112, 93 94 18 11, tab 100
  check "Alternative colour matching mode (slower)", 113, 12 106 146 11, tab 100
  text "Colour palette:", 114, 12 121 49 11, tab 100
  combo 115, 63 120 90 14, tab 100 drop
  button "Help", 116, 39 161 60 14, tab 100
  text "", 199, 6 214 10 10, tab 100 hide
  tab "Text file", 200
  edit "", 201, 12 25 200 11, tab 200 autohs read
  button "Browse", 202, 162 38 50 13, tab 200
  text "Filler padding:", 203, 13 40 47 11, tab 200
  combo 204, 62 39 40 14, tab 200 drop
  link "Help", 205, 106 40 18 11, tab 200
  tab "Clipboard", 300
  text "Filler padding:", 301, 13 29 47 11, tab 300
  combo 302, 62 28 40 14, tab 300 drop
  link "Help", 303, 106 29 18 11, tab 300
}

on *:dialog:pe.import:init:0: {
  if (%pixed.insert !isnum 0-1) %pixed.insert = 0
  if (%pixed.insert) did -c pe.import 10
  else did -b pe.import 11,12
  didtok pe.import 12 32 none 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98
  if ($didwm(12,%pixed.transparent)) did -c pe.import 12 $v1
  else did -c pe.import 12 1
  if (%pixed.aspectratio !isnum 0-1) %pixed.aspectratio = 1
  if (%pixed.aspectratio) did -c pe.import 109
  if (%pixed.highquality !isnum 0-1) %pixed.highquality = 1
  if (%pixed.highquality) did -c pe.import 110
  if (%pixed.triplewidth) did -c pe.import 111
  if ($group(#pe.method2) == on) did -c pe.import 113
  didtok pe.import 115 44 All colours,Classic (0-15),Grayscale (88-98)
  if (%pixed.palette !isnum 1-3) %pixed.palette = 1
  did -c pe.import 115 %pixed.palette
  didtok pe.import 204,302 32 1 2 3 4 5
  if (%pixed.padding !isnum 1-5) %pixed.padding = 1
  did -c pe.import 204,302 %pixed.padding
  tokenize 32 %pe.import
  if ($1 == image) pe.importimage $2-
  elseif ($1 == text) {
    %pixed.lasttext = $nofile($2-)
    did -a pe.import 201 $2-
    .timerpe.import -om 1 0 did -c pe.import 200
  }
  else .timerpe.import -om 1 0 did -c pe.import 300
  unset %pe.import
}

alias -l pe.processline {
  set -l %line $strip($replacex($1-,$chr(32),_),buri)
  set -l %fixed $replace(%line,$chr(15),$chr(3))
  set -l %colour $color(background)
  set -l %bg $color(background)
  set -l %pos 1
  set -l %x
  set -l %row1
  set -l %row2
  if ($pos(%fixed,$chr(3),1) > 1) set -l %pre $str($color(background) $chr(32),$round($calc($len($gettok(%fixed,1,3)) /%pixed.padding),0))
  else set -l %pre
  while ($pos(%fixed,$chr(3),%pos)) {
    %x = $v1 + 1
    if ($mid(%line,$v1,1) == $chr(3)) {
      tokenize 44 $mid(%line,%x,5)
      if ($1 isnum 0-99) {
        %colour = $v1
        if ($left($2,2) isnum) || ($left($2,1) isnum) {
          %bg = $v1
          inc %x $len(%colour $v1)
        }
        else inc %x $len(%colour)
      }
      elseif ($left($1,2) isnum) || ($left($1,1) isnum) {
        %colour = $v1
        inc %x $len($v1)
      }
      else {
        %colour = $color(background)
        %bg = $color(background)
      }
    }
    if ($gettok($mid(%fixed,%x),1,3) != $null) {
      set -l %padding $v1
      if ($remove(%padding,$chr(9600),$chr(9604),$chr(9608)) == $null) {
        %x = 1
        while ($mid(%padding,%x,1) != $null) {
          tokenize 1 $v1
          if ($1 == $chr(9600)) tokenize 32 %colour %bg
          elseif ($1 == $chr(9604)) tokenize 32 %bg %colour
          else tokenize 32 %colour %colour
          %row1 = %row1 $1 $chr(32)
          %row2 = %row2 $2 $chr(32)
          inc %x
        }
      }
      else %row1 = %row1 $str(%bg $chr(32),$round($calc($len(%padding) /%pixed.padding),0))
    }
    inc %pos
  }
  if ($numtok(%row1,32) > %pe.importwidth) %pe.importwidth = $v1
  if ($numtok(%row2,32) > %pe.importwidth) %pe.importwidth = $v1
  if (%row1 != $null) aline -l @pe.temp %pre $v1
  if (%row2 != $null) aline -l @pe.temp %pre $v1
}

alias -l pe.drawrowmain {
  tokenize 32 $gettok($1,1-256,32)
  set -l %x 0
  while ($1 isnum) {
    drawrect -nf @pe.mirror $1 1 %x %pe.y %pe.rectangle
    tokenize 32 $2-
    inc %x %pixed.size
  }
  inc %pe.y %pixed.size
}

alias -l pe.drawrowinsert {
  tokenize 32 $gettok($1,1-256,32)
  set -l %x 1
  while ($1 isnum) {
    if ($1 == %pixed.transparent) drawrect -rnf @pe.tool %pe.transparent 1 %x %pe.y %pe.rectangle
    else drawrect -nf @pe.tool $1 1 %x %pe.y %pe.rectangle
    tokenize 32 $2-
    inc %x %pixed.size
  }
  inc %pe.y %pixed.size
}

on *:dialog:pe.import:sclick:2: {
  tokenize 1 $dialog(pe.import).tab
  if ($1 == 200) || ($1 == 300) {
    %pe.importwidth = 1
    clear -l @pe.temp
    if ($1 == 200) {
      if (!$isfile($did(201))) {
        did -r pe.import 201
        noop $input(No file selected.,ohu,Pixel Editor)
        return
      }
      filter -fkr 1-256 $qt($did(201)) pe.processline
    }
    else {
      set -l %i 1
      if ($cb(0) <= 256) set -l %m $v1
      else set -l %m 256
      while (%i <= %m) {
        pe.processline $replacex($cb(%i,u),$chr(32),_)
        inc %i
      }
    }
    dialog -c pe.import
    pe.tip Processing...
    if (%pixed.insert) {
      if (%pe.importwidth <= 256) set -l %w $v1
      else set -l %w 256
      if ($iif($line(@pe.temp,0,1),$v1,1) <= 256) set -l %h $v1
      else set -l %h 256
      %pe.copy = 0 0 %w %h
      clear -n @pe.tool
      drawsize @pe.tool $calc(%w *%pixed.size) $calc(%h *%pixed.size)
      drawline -rn @pe.tool %pe.frame 1 $pe.grid(%w,%h)
      %pe.y = 1
      filter -wlkr 1-256 @pe.temp pe.drawrowinsert
      pe.tool select
      pe.mirror
      pe.copy %pe.copy
      drawdot @Pixel
    }
    else {
      unset %pe.copy
      pe.clearredo
      pe.clearundo
      if (%pe.importwidth <= 256) set -l %w $v1
      else set -l %w 256
      if ($iif($line(@pe.temp,0,1),$v1,1) <= 256) set -l %h $v1
      else set -l %h 256
      pe.checksize
      pe.update
      titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
      clear -n @pe.mirror
      drawsize @pe.mirror %pe.width %pe.height
      drawline -nr @pe.mirror %pe.frame 1 %pe.grid
      %pe.y = 0
      filter -wlkr 1-256 @pe.temp pe.drawrowmain
      window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
      pe.mirror
      drawdot @Pixel
    }
  }
  elseif ($1 == 100) {
    if (!$isfile($did(101))) {
      did -r pe.import 101
      noop $input(No file selected.,ohu,Pixel Editor)
      return
    }
    %pixed.lastimage = $nofile($did(101))
    if ($did(105) !isnum 1-) || ($did(107) !isnum 1-) pe.importimage $did(101)
    set -l %w $did(105)
    if (%pixed.triplewidth) %w = $did(105) * 3
    if (%w > 256) %w = 256
    if ($did(107) <= 256) set -l %h $v1
    else set -l %h 256
    if ($calc(%w *%h) >= 5000) {
      if ($input($+(You are about to import an image that consists of $bytes($v1,b) pixels. Loading large images can take a very long time.,$crlf,$crlf,Do you want to continue?),ywu,Pixel Editor)) noop
      else return
    }
    pe.tip Processing...
    if (%pixed.palette != 1) pe.palette
    dialog -c pe.import
    clear -n @pe.temp
    drawsize @pe.temp %w %h
    drawpic $iif(%pixed.highquality,-nsm,-ns) @pe.temp 0 0 %w %h $qt($did(101))
    if (%pixed.insert) {
      if (%pixed.transparent isnum 0-98) set -l %transparent $color(%pixed.transparent)
      else set -l %transparent
      %pe.copy = 0 0 %w %h
      clear -n @pe.tool
      drawsize @pe.tool $calc(%w *%pixed.size) $calc(%h *%pixed.size)
      drawline -rn @pe.tool %pe.frame 1 $pe.grid(%w,%h)
      set -l %x
      set -l %a
      set -l %y 0
      set -l %b 0
      while (%b < %h) {
        %x = 0
        %a = 0
        while (%a < %w) {
          tokenize 1 $pe.match($getdot(@pe.temp,%a,%b))
          if ($1 == %transparent) drawrect -rnf @pe.tool %pe.transparent 1 %x %y %pe.rectangle
          else drawrect -rnf @pe.tool $1 1 %x %y %pe.rectangle
          inc %x %pixed.size
          inc %a
        }
        inc %y %pixed.size
        inc %b
      }
      pe.tool select
      pe.mirror
      pe.copy %pe.copy
      drawdot @Pixel
    }
    else {
      unset %pe.copy
      pe.clearredo
      pe.clearundo
      %pixed.width = %w
      %pixed.height = %h
      pe.checksize
      pe.update
      titlebar @Pixel Editor - %pixed.width x %pixed.height - /PE
      clear -n @pe.mirror
      drawsize @pe.mirror %pe.width %pe.height
      drawline -nr @pe.mirror %pe.frame 1 %pe.grid
      set -l %x
      set -l %a
      set -l %y 0
      set -l %b 0
      while (%b < %pixed.height) {
        %x = 0
        %a = 0
        while (%a < %pixed.width) {
          drawrect -rnf @pe.mirror $pe.match($getdot(@pe.temp,%a,%b)) 1 %x %y %pe.rectangle
          inc %x %pixed.size
          inc %a
        }
        inc %y %pixed.size
        inc %b
      }
      window -f @Pixel -1 -1 $calc(199+%pe.width) $calc(%pe.height -1)
      pe.mirror
      drawdot @Pixel
      if (%pixed.palette != 1) pe.palette 1
    }
  }
}

on *:dialog:pe.import:sclick:10: {
  %pixed.insert = $did(10).state
  did $iif(%pixed.insert,-e,-b) pe.import 11,12
}

on *:dialog:pe.import:sclick:12:%pixed.transparent = $did(12)

on *:dialog:pe.import:sclick:103:if ($sfile($iif($isdir(%pixed.lastimage),%pixed.lastimage,$mircdir) $+ *.bmp;*.png;*.jpg;*.jpeg;*.gif,Choose an image file to import,Select)) pe.importimage $v1

alias -l pe.importimage {
  did -ra pe.import 101 $1-
  set -l %w $pic($1-).width
  set -l %h $pic($1-).height
  did -ra pe.import 199 %w %h
  if ($max(%w,%h) <= 256) did -z pe.import 108 1 $v1
  else did -z pe.import 108 1 256
  :again
  if (%h > 20) {
    set -l %w $round($calc(20*(%w /%h)),0)
    set -l %h 20
    goto again
  }
  if (%w > 44) {
    set -l %h $round($calc(44*(%h /%w)),0)
    set -l %w 44
    goto again
  }
  did -ra pe.import 105 %w
  did -ra pe.import 107 %h
  did -c pe.import 108 %w
}

on *:dialog:pe.import:edit:105: {
  tokenize 32 $did(199)
  if ($did(105) > 256) did -ra pe.import 105 256
  if (%pixed.aspectratio) did -ra pe.import 107 $iif($iif($round($calc($did(105)*($2 /$1)),0) isnum 1-,$v1,1) <= 256,$v1,256)
  did -c pe.import 108 $did(105)
}

on *:dialog:pe.import:edit:107: {
  tokenize 32 $did(199)
  if ($did(107) > 256) did -ra pe.import 107 256
  if (%pixed.aspectratio) did -ra pe.import 105 $iif($iif($round($calc($did(107)*($1 /$2)),0) isnum 1-,$v1,1) <= 256,$v1,256)
  did -c pe.import 108 $did(105)
}

on *:dialog:pe.import:scroll:108: {
  tokenize 32 $did(199)
  did -ra pe.import 105 $did(108).sel
  did -ra pe.import 107 $round($calc($did(105)*($2 /$1)),0)
}

on *:dialog:pe.import:sclick:109:%pixed.aspectratio = $did(109).state

on *:dialog:pe.import:sclick:110:%pixed.highquality = $did(110).state

on *:dialog:pe.import:sclick:111:%pixed.triplewidth = $did(111).state

on *:dialog:pe.import:sclick:112: {
  set -l %m When this option is enabled, Pixel Editor will multiply the given width by three.\n\n $+ $&
    This can be useful when using basic encoding method with a single non-breaking space as filler, or double (horizontal), as it will increase the horizontal detail, while keeping the correct aspect ratio.
  noop $input($replacex(%m,\n,$crlf),oiu,Pixel Editor)
}

on *:dialog:pe.import:sclick:113: {
  hdel -w pe.db *
  if ($group(#pe.method2) == on) {
    .enable #pe.method1
    .disable #pe.method2
  }
  else {
    .disable #pe.method1
    .enable #pe.method2
  }
}

on *:dialog:pe.import:sclick:115:%pixed.palette = $did(115).sel

alias -l pe.palette {
  hdel -w pe.db *
  hdel -w pe.colours *
  if (%pixed.palette == 1) || ($1) tokenize 32 98 0
  elseif (%pixed.palette == 2) tokenize 32 15 0
  else tokenize 32 98 88
  set -l %c $1
  set -l %e $2
  while (%c >= %e) {
    hadd pe.colours $rgb($color(%c)) $color(%c)
    hadd pe.mirc $color(%c) %c
    dec %c
  }
}

on *:dialog:pe.import:sclick:116:pe.encodinginput

alias -l pe.encodinginput {
  set -l %m The maximum length of a message on a standard IRC server is 512 bytes, which includes carriage return, line feed and parameters. That leaves you with approximately 350-400 bytes to play with.\n\n $+ $&
    Basic encoding method uses given filler, which means the bytes per pixel count can vary massively. A safe estimate is 8 bytes per pixel, which means you can fit around 50-60 pixels per line.\n\n $+ $&
    Double (vertical) enconding method fits two vertical pixels on the same line. This can take up to 9 bytes per double pixel, meaning the worst case scenario is 44 pixels, but you are likely to be able to fit over 50 pixels on a single line.\n\n $+ $&
    Double (horizontal) encoding method fits two horizontal pixels in one pixel. This can take up to 9 bytes per double pixel, meaning the worst case scenario is 88 pixels, but you are likely to be able to fit over 100 on a single line.\n\n $+ $&
    Double (vertical) is the recommended encoding method.
  noop $input($replacex(%m,\n,$crlf),oiu,Pixel Editor)
}

on *:dialog:pe.import:sclick:202: {
  if ($sfile($iif($isfile(%pixed.lasttext),%pixed.lasttext,$mircdir) $+ *.txt;*.log,Choose a text file to import,Select)) {
    did -a pe.import 201 $v1
    %pixed.lasttext = $nofile($v1)
  }
}

on *:dialog:pe.import:sclick:204,302: {
  %pixed.padding = $did($did)
  did -c pe.import 204,302 $did($did).sel
}

on *:dialog:pe.import:sclick:205,303:noop $input(If a pixel consists of more than one character $+ $chr(44) this value should be increased to match the number of characters.,oiu,Pixel Editor)
