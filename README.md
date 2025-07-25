# Fibonacci Bignum Generator in x86_64 Assembly

This project generates arbitrarily large Fibonacci numbers using hand-written arbitrary-precision arithmetic in pure x86_64 NASM assembly, with direct Linux syscall I/O — no standard library required.

It is designed to demonstrate low-level big number computation, efficient output handling, and command-line driven generation of the Fibonacci sequence with optional file splitting and size limitation.


## Features

- Manual arbitrary-precision addition using byte buffers (up to 256-byte integers)
- Optimized for performance using syscall-based I/O (write syscall, no `libc`)
- Direct conversion from big integers to base-10 strings
- Buffered output for fast file writes
- C wrapper provides flexible CLI with options for output size and file splitting
- Full debug visibility via stderr
- Clean, modular NASM architecture:
  - `big_add`: High-precision addition
  - `big_to_str`: Binary to decimal string conversion
  - `write_buffered`: Batched writes via buffer
  - `generate_fibonacci`: Top-level sequence controller

## 🔧 Build Instructions

### Compile C Wrapper
```bash
gcc -no-pie -g -c main.c -o main.o 2> build.log
```

### Assemble the NASM Module
```bash
nasm -felf64 -g -F dwarf fibonacci.asm -o fibonacci.o 2>> build.log
```

### Link C and ASM
```bash
gcc -no-pie main.o fibonacci.o -o fibonacci 2>> build.log
```

### Check for Build Errors
```bash
cat build.log
```

## ▶️ Usage

### Basic Usage
```bash
./fibonacci --file=output.txt --size=100 --unit=k
```

### CLI Options
- `--file=<filename>`: Output file (default: fib.txt)
- `--size=<number>`: Total output size (default: 1048576)
- `--unit=<b|k|m|g|t|p>`: Size unit (bytes, KB, MB, GB, TB, PB)
- `--split=<number>`: Number of output files (default: 1)
- `--splitsize=<number>`: Size per file (required if split > 1)
- `--splitunit=<b|k|m|g|t|p>`: Unit for split size (default: b)
- `--stop`: Stop writing once the size limit is reached
- `--help`: Show usage help

### Examples
```bash
./fibonacci --file=seq.txt --size=256 --unit=b
./fibonacci --file=myfib.txt --size=50 --unit=k
./fibonacci --file=multi --split=3 --splitsize=10 --splitunit=k
```

## 🧪 Debugging Example

Run with debug output:
```bash
rm -f sequence.txt
./fibonacci --file=sequence.txt --size=256 --unit=b 2> debug.log
cat debug.log
ls -lh sequence.txt
cat sequence.txt
```

### Sample Debug Output
`debug.log` will contain:
```
Opening sequence.txt with size 256 bytes
Calling generate_fibonacci for sequence.txt, size=256, fd=3
Stopping: total size 256 reached
```

You can use this output for regression testing or setting GDB breakpoints.

## 📄 Output Format

Each Fibonacci number is printed on its own line in decimal:
```
0
1
1
2
3
5
8
13
...
```

The output stops exactly when the size limit is reached, or per-file limits are respected when `--split` is used.

## 🧠 Domain

This program is intended for:
- High-Performance Computing (HPC)
- Low-level systems programming
- Educational demonstration of assembly-level big integer arithmetic
- Compact benchmark tool for syscall-based I/O throughput

## 📜 License

This project is licensed under the GNU General Public License v3.0.

You are free to:
- Use, study, and modify the code
- Distribute modified versions under the same license
- Use it for educational, research, or production purposes

For more details, see the LICENSE file.

## 👤 Author

Thibaut LOMBARD  
GitHub: [https://github.com/Lombard-Web-Services](https://github.com/Lombard-Web-Services)  
Project Repository: [Big-Num-Fibo](https://github.com/Lombard-Web-Services/Big-Num-Fibo)  
Alias: [@lombardweb](https://github.com/lombardweb)
