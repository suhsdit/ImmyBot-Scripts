# Install the core boards using configuration file:
SET "PATH_ARDUINO_CLI=C:\Program Files\arduino-ide\resources\app\node_modules\arduino-ide-extension\build\arduino-cli.exe"
SET "PATH_ARDUINO_CLI_CONFIG=C:\Program Files\arduino-ide\Appdata\arduino-cli.yaml"
START /WAIT "" "%PATH_ARDUINO_CLI%" core install arduino:avr     --config-file "%PATH_ARDUINO_CLI_CONFIG%"