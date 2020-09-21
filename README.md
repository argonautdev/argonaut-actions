# Hello world docker action

This action prints "Hello Jason" or "Hello" + the name of a person to greet to the log.

## Inputs

### `who-to-greet`

**Required** The name of the person to greet. Default `"Jason"`.

## Outputs

### `time`

The time we greeted you.

## Example usage

uses: argonautdev/argonaut-actions@0.0.1
with:
who-to-greet: 'Jason the Argonaut'
