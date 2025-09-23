@echo off

echo Buuild luvix...

python bundleit.py -o ../containers/desktop/engine.bundle.lua -m main.lua ../common/

pause