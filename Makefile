APP := build/Scroll Wheel Mission Control.app
VERSION ?= $(shell cat VERSION)

.PHONY: app test install dmg art screenshots clean

## Build the universal app bundle into build/
app:
	VERSION=$(VERSION) ./scripts/build-app.sh

## Check keyboard shortcut event sequences without posting system input
test:
	zsh Tests/run.sh

## Build and copy the app to /Applications
install: app
	rm -rf "/Applications/Scroll Wheel Mission Control.app"
	cp -R "$(APP)" /Applications/
	@echo "Installed to /Applications. Open it from Spotlight or Launchpad."

## Build and package the release DMG and zip into dist/
dmg: app
	VERSION=$(VERSION) ./scripts/package-dmg.sh

## Re-render the icon and README artwork
art:
	swift scripts/generate-art.swift

## Re-render the settings window screenshots
screenshots:
	./scripts/render-screenshots.sh

clean:
	rm -rf .build build dist
