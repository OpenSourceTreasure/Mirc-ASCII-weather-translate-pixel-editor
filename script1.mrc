].on *:TEXT:!weather *:#: {
  var %location = $1
  if ($len(%location) == 0) {
    msg $chan Usage: !weather <location>
    return
  }

  ; Validate input
  if ($wildsite(%location)) {
    msg $chan Invalid input. Please enter a valid location.
    return
  }

  var %weatherFile = $+($mircdir,weather.txt)
  ; Execute curl command and save output to a file
  .run -r %windir%\syswow64\curl.exe -o %weatherFile wttr.in/%location?format=j1

  ; Check for errors
  if ($error) {
    msg $chan Error: Failed to retrieve weather information for %location.
    .remove %weatherFile
    return
  }

  ; Read the contents of the file
  var %weather = $read(%weatherFile)

  ; Check for errors
  if (!$error) {
    msg $chan Debug: %weatherFile
    msg $chan %weather
  }
  else {
    msg $chan Error: Failed to retrieve weather information for %location.
  }

  ; Delete the temporary file
  .remove %weatherFile
}
