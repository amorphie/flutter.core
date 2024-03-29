clean:
	flutter clean

lint:
	flutter analyze --fatal-infos --fatal-warnings

runner:
	flutter clean
	dart run build_runner build --delete-conflicting-outputs

get:
	flutter pub get

format:
	dart format --line-length=120 .

test:
	flutter test
