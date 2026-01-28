# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.5] - 2026-01-28

### Added
- Comprehensive DocC documentation for all 15 Hotwire Native bridge components.
- Standardized `// MARK:` groupings across all bridge components and view controllers for better code navigation.
- Developer-centric comments explaining bridge component events and message data structures.

### Changed
- Refactored `ThemeComponent` to use Swift's `Decodable` for theme mode switching, replacing manual `JSONSerialization`.
- Optimized `LocationComponent` by removing redundant button setup logic and unused code.
- Improved internal JSON handling and code structure in `MobikulShareButtonComponent` (CustomShareButton.swift).
- Enhanced `NavButtonComponent` with better caching and removal logic for bar buttons.

### Removed
- Extensive blocks of commented-out code in `LocationComponentController.swift`.
