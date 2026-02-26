# PicoASM

Simple assembler for our custom CPU architecture.

## Build

- Download and install the [.NET 10 SDK](https://dotnet.microsoft.com/en-us/download)
- Clone the repository and navigate to the project directory
- Run the following command to build the project:
	```shell
	dotnet publish -c Release
	```

## Usage

To use the assembler, simply run the `PicoAsm` executable with the path to your assembly file as an argument:
```shell
./PicoAsm path/to/your/assembly.asm
```

The assembled machine-code will be written to stdout as vhdl that can directly be pasted into the `rom` component of the CPU design.

## License

This project is licensed under the [MIT License](./LICENSE).
