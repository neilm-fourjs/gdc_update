IMPORT os
#CONSTANT C_DEFVER = "3.10"
#CONSTANT C_DEFBLD = "25-build201908011616"
CONSTANT C_DEFVER = "3.20"
CONSTANT C_DEFBLD = "09-build201910181616"
CONSTANT C_CHOOSE_TEMP_LOC = FALSE
MAIN
  DEFINE l_file, l_updatepath, l_tmpPath STRING
  DEFINE l_res, l_ver, l_target, l_sep STRING
  DEFINE l_oldVer, l_newVer, l_newBuild STRING
  -- Use args for the version & build and use defaults if not supplied.
  LET l_newVer = NVL(ARG_VAL(1), C_DEFVER)
  LET l_newBuild = NVL(ARG_VAL(2), C_DEFBLD)
  -- Gets the update zip file name
  LET l_ver = SFMT("%1.%2", l_newVer, l_newBuild)
  CALL ui.interface.frontCall("standard", "feInfo", "target", l_target)
  LET l_sep = IIF(l_target.getCharAt(1) = "w", "\\", "/")
  LET l_file = SFMT("fjs-gdc-%1-%2-autoupdate.zip", l_ver, l_target)
  LET l_updatepath = SFMT("%1/FourJs_Downloads/%2/gdc/%3", fgl_getEnv("HOME"), l_newVer, l_file)
  LET l_oldVer = ui.interface.getFrontEndVersion()
  -- Display some useful info to the console
  CALL log(
      __LINE__,
      SFMT("oldVer: %1 newVer: %2 Build: %3 Target: %4 Media: %5",
          l_oldVer, l_newVer, l_newBuild, l_target, l_updatepath))

  -- Makes sure the file path exists
  IF NOT os.path.exists(l_updatepath) THEN
    CALL fgl_winmessage(%"GDC Update File", SFMT(%"Update Archive Missing.\n%1", l_updatepath), "exclamation")
    CALL log(__LINE__, "No Archive, aborting!")
    EXIT PROGRAM
  END IF

  -- Need to save update file on client
  IF C_CHOOSE_TEMP_LOC THEN -- Choose where to save this file for the update
    CALL winsavefile(l_file, "zip", "*.zip", "File name:") RETURNING l_tmpPath
  ELSE -- Don't choose, just find temp folder
    CALL ui.interface.frontCall("standard", "getEnv", "TEMP", l_tmpPath)
    IF l_tmpPath IS NULL AND l_target.getCharAt(1) = "l" THEN -- Linux
      CALL ui.interface.frontCall("standard", "getEnv", "HOME", l_tmpPath)
    END IF
    LET l_tmpPath = l_tmpPath.append(l_sep || l_file)
  END IF

  CALL log(__LINE__, SFMT("tmpPath: %1", l_tmpPath))
  IF l_tmpPath IS NULL THEN
    CALL log(__LINE__, "tmpPath NULL, aborting!")
    EXIT PROGRAM
  END IF

  -- Our confirm
  IF fgl_winQuestion("Update", SFMT("Update GDC?\n%1\n%2", l_oldVer, l_ver), "yes", "yes|no", "question", 0) = "no" THEN
    CALL log(__LINE__, "Aborted by user")
    EXIT PROGRAM
  END IF

  -- Puts the update archive in the folder where the GDC is installed
  TRY
    CALL fgl_putfile(l_updatepath, l_tmpPath)
  CATCH
    CALL log(__LINE__, SFMT("Putfile failed: %1 %2, aborting!", STATUS, ERR_GET(STATUS)))
    EXIT PROGRAM
  END TRY
  -- Run the update
  CALL ui.Interface.frontCall("monitor", "update", [l_tmpPath], [l_res])
  CALL log(__LINE__, SFMT("Finished: %1", STATUS))

END MAIN
--------------------------------------------------------------------------------
FUNCTION log(l_line SMALLINT, l_mess STRING)
  DEFINE c base.channel
  LET c = base.Channel.create()
  CALL c.openFile("gdc_upd.log", "a+")
  CALL c.writeLine(SFMT("%1:%2:%3", l_line, CURRENT, NVL(l_mess, "NULL")))
  CALL c.close()
END FUNCTION
