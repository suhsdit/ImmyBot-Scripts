@ECHO OFF
SET "CONFIG_NAME=arduino-cli.yaml"
SET "ARDUINO_CLI=C:\Program Files\arduino-ide\resources\app\node_modules\arduino-ide-extension\build\arduino-cli.exe"

SET "APPDATALOCAL_DIR=C:\Program Files\arduino-ide\Appdata"
SET "CONFIG_USER_DIR=%userprofile%\.arduinoIDE"
SET "CONFIG_USER_FILE=%CONFIG_USER_DIR%\%CONFIG_NAME%"
SET "CONFIG_BLANK_FILE=%APPDATALOCAL_DIR%\%CONFIG_NAME%"


IF NOT EXIST "%CONFIG_USER_DIR%"  MD "%CONFIG_USER_DIR%"
IF NOT EXIST "%CONFIG_USER_FILE%" XCOPY "%CONFIG_BLANK_FILE%" "%CONFIG_USER_DIR%" /I/Q/H/R/K/Y/S/E
ATTRIB +h "%CONFIG_USER_DIR%"

"%ARDUINO_CLI%" config set directories.data      "%APPDATALOCAL_DIR%\Local\Arduino15"         --config-file "%CONFIG_USER_FILE%"
"%ARDUINO_CLI%" config set directories.downloads "%APPDATALOCAL_DIR%\Local\Arduino15\staging" --config-file "%CONFIG_USER_FILE%"

START "" "C:\Program Files\arduino-ide\Arduino IDE.exe"

EXIT /B 0
