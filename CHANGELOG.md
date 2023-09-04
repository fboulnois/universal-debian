# Changelog

## [v1.0.20](https://github.com/fboulnois/universal-debian/compare/v1.0.19...v1.0.20) - 2023-09-04

### Added

* Add git alias to purge old data

## [v1.0.19](https://github.com/fboulnois/universal-debian/compare/v1.0.18...v1.0.19) - 2023-07-16

### Added

* Add cargo alias to show reverse dependencies

## [v1.0.18](https://github.com/fboulnois/universal-debian/compare/v1.0.17...v1.0.18) - 2023-05-22

### Added

* Update rustup to 1.26.0

## [v1.0.17](https://github.com/fboulnois/universal-debian/compare/v1.0.16...v1.0.17) - 2023-04-24

### Added

* Add Dockerfile

### Fixed

* Ensure volta is on path during install

## [v1.0.16](https://github.com/fboulnois/universal-debian/compare/v1.0.15...v1.0.16) - 2023-04-17

### Fixed

* Simplify node and pnpm installation

## [v1.0.15](https://github.com/fboulnois/universal-debian/compare/v1.0.14...v1.0.15) - 2023-02-22

### Added

* Update volta to v1.1.1
* Update rustup to v1.25.2

### Changed

* Reorder git settings alphabetically

### Fixed

* Remove extra newline for alias
* Switch ssh key name for clarity

## [v1.0.14](https://github.com/fboulnois/universal-debian/compare/v1.0.13...v1.0.14) - 2022-11-28

### Added

* Install git-lfs to track large files
* Switch from nvm to volta

### Changed

* Simplify wsl home detection

### Fixed

* Return only a single wsl home

## [v1.0.13](https://github.com/fboulnois/universal-debian/compare/v1.0.12...v1.0.13) - 2022-10-31

### Added

* Update rustup to v1.25.1
* Update nvm to v0.39.2

### Fixed

* Simplify pnpm version check

## [v1.0.12](https://github.com/fboulnois/universal-debian/compare/v1.0.11...v1.0.12) - 2022-10-05

### Added

* Autostash git changes on rebase

### Changed

* Move git config into separate function

### Fixed

* Add more robust wsl home checking

## [v1.0.11](https://github.com/fboulnois/universal-debian/compare/v1.0.10...v1.0.11) - 2022-09-21

### Added

* Cache git credentials

### Fixed

* Add more robust version checking for pnpm

## [v1.0.10](https://github.com/fboulnois/universal-debian/compare/v1.0.9...v1.0.10) - 2022-07-29

### Fixed

* Add newlines to ensure alias is active

## [v1.0.9](https://github.com/fboulnois/universal-debian/compare/v1.0.8...v1.0.9) - 2022-07-21

### Changed

* Add --dry-run to gpg command

### Fixed

* Remove amd64 from docker sources

## [v1.0.8](https://github.com/fboulnois/universal-debian/compare/v1.0.7...v1.0.8) - 2022-07-08

### Added

* Set git default branch to main

### Changed

* Switch to using built-in wsl config
* Securely install docker

## [v1.0.7](https://github.com/fboulnois/universal-debian/compare/v1.0.6...v1.0.7) - 2022-05-27

### Added

* Set git config pull.rebase as default

### Changed

* Install nvm similar to rustup

## [v1.0.6](https://github.com/fboulnois/universal-debian/compare/v1.0.5...v1.0.6) - 2022-05-26

### Added

* Install latest version of pnpm
* Check rustup sha256 before executing

## [v1.0.5](https://github.com/fboulnois/universal-debian/compare/v1.0.4...v1.0.5) - 2022-05-12

### Added

* Alias yarn to pnpm

## [v1.0.4](https://github.com/fboulnois/universal-debian/compare/v1.0.3...v1.0.4) - 2022-05-01

### Added

* Update pnpm to 7.0.0
* Update pnpm to 7.0.0-rc.8

## [v1.0.3](https://github.com/fboulnois/universal-debian/compare/v1.0.2...v1.0.3) - 2022-04-10

### Changed

* Put pnpm install in separate step
* Switch from yarn to pnpm

## [v1.0.2](https://github.com/fboulnois/universal-debian/compare/v1.0.1...v1.0.2) - 2022-03-23

### Added

* Always install node lts

## [v1.0.1](https://github.com/fboulnois/universal-debian/compare/v1.0.0...v1.0.1) - 2022-03-13

### Added

* Disable x11 forwarding with ssh
* Add more hardening for ssh

## [v1.0.0](https://github.com/fboulnois/universal-debian/releases/tag/v1.0.0) - 2022-02-19

### Added

* Initial release
