# 1. SwiftGen for Strings and Assets

Date: 2022-08-30

## Status

Accepted

## Context

Our UI requires translations (strings) and images (stored in asset catalogs). Those are usually accessed via string keys and thus are not checked by the compiler.

## Decision

We use [SwiftGen](https://github.com/SwiftGen/SwiftGen) to automatically extract all available assets and strings into generated enums/constants.

## Consequences

We only access strings and assets through generated code. Missing or wrongly named keys and assets will result in failure at compile time and not at runtime.
