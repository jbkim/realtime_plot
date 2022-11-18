#!/bin/bash

rm -r *.zip

rm -r application.linux32
rm -r application.linux-armv6hf
rm -r application.linux-arm64
rm -r application.linux-armv6hf

mv application.linux64 realtime_plot-linux64
zip -r realtime_plot-linux64.zip realtime_plot-linux64

mv application.macosx realtime_plot-macosx
cp data/sketch.icns realtime_plot-macosx/realtime_plot.app/Contents/
codesign -s "Apple Development: Jinbuhm Kim (Y6BR7V7C38)" realtime_plot-macosx/realtime_plot.app
zip -r realtime_plot-macosx.zip realtime_plot-macosx

mv application.windows32 realtime_plot-windows32
zip -r realtime_plot-windows32.zip realtime_plot-windows32

mv application.windows64 realtime_plot-windows64
zip -r realtime_plot-windows64.zip realtime_plot-windows64

rm -r -f realtime_plot-linux64
rm -r -f realtime_plot-macosx
rm -r -f realtime_plot-windows32
rm -r -f realtime_plot-windows64

