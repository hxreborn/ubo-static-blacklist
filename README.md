# ubo-static-blacklist

Personal uBlock Origin filter lists to remove annoyances.

## How to use

1.  In uBlock Origin's settings, go to the "Filter lists" tab.
2.  Under "Custom", add these URLs:
    ```
    https://raw.githubusercontent.com/hxreborn/ubo-static-blacklist/main/general-cosmeric-search-filters.txt
    https://raw.githubusercontent.com/hxreborn/ubo-static-blacklist/main/mobile-cosmetic-filters.txt
    ```
3.  Apply changes.

## Important

You need to set `allowGenericProceduralFilters` to `true` in advanced settings for this to work.
[More info](https://github.com/gorhill/uBlock/wiki/Advanced-settings#allowgenericproceduralfilters)

## Compatibility

These lists are tested on recent versions of Firefox and Chrome. Use at your own risk on other browsers.
The move to Manifest V3 may break things on Chromium browsers in the future.
