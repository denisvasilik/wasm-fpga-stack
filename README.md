# WebAssembly FPGA Stack

This repository implements the [stack](https://www.w3.org/TR/wasm-core-1/#stack)
used by the WebAssembly runtime.

## Documentation

Documentation is available from [wasm-fpga.readthedocs.io].

[wasm-fpga.readthedocs.io]: https://wasm-fpga.readthedocs.io/en/latest/

## Get in touch

- Report bugs, suggest features or view the source code [on GitHub].
- For contributions refer to [the contributors guide].

[on GitHub]: https://github.com/denisvasilik/wasm-fpga

## Continuous Integration (CI)

This repository contains a `.travis.yml` and a `ci` folder which both are used
for CI.

### Pre-Commit Hooks

This repository provides `pre-commit` and `pre-push` hooks. They are installed
using the following commands:

```console
~$ pre-commit install -t pre-commit
~$ pre-commit install -t pre-push
```

The following command runs the hooks and checks all files.

```console
~$ pre-commit run --all-files --hook-stage push
```

# License

Licensed under the MIT license ([LICENSE-MIT] or http://opensource.org/licenses/MIT).

[the contributors guide]: CONTRIBUTING.md
[LICENSE-MIT]: LICENSE.rst
