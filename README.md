# 🔢 Fibonacci Bignum Generator in x86_64 Assembly 

This project generates arbitrarily large Fibonacci numbers using hand-written arbitrary-precision arithmetic in pure x86_64 NASM assembly, with direct Linux syscall I/O — no standard library required.

It is designed to demonstrate low-level big number computation, efficient output handling, and command-line driven generation of the Fibonacci sequence with optional file splitting and size limitation.



## 🚀 Features 

* Manual arbitrary-precision addition using byte buffers (up to 256-byte integers)

* Optimized for performance using syscall-based I/O (write syscall, no `libc`)

* Direct conversion from big integers to base-10 strings

* Buffered output for fast file writes

* C wrapper provides flexible CLI with options for output size and file splitting

* Full debug visibility via stderr

* Clean, modular NASM architecture:

  * `big_add`: High-precision addition

  * `big_to_str`: Binary to decimal string conversion

  * `write_buffered`: Batched writes via buffer

  * `generate_fibonacci`: Top-level sequence controller



## 🔧 Build Instructions 

### Compile C Wrapper

```
gcc -no-pie -g -c main.c -o main.o 2> build.log

```

### Assemble the NASM Module

```
nasm -felf64 -g -F dwarf fibonacci.asm -o fibonacci.o 2>> build.log

```

### Link C and ASM

```
gcc -no-pie main.o fibonacci.o -o fibonacci 2>> build.log

```

### Check for Build Errors

```
cat build.log

```



## ▶️ Usage 

### Basic Usage

```
./fibonacci --file=output.txt --size=100 --unit=k

```

### CLI Options

* `--file=<filename>`: Output file (default: fib.txt)

* `--size=<number>`: Total output size (default: 1048576)

* `--unit=<b|k|m|g|t|p>`: Size unit (bytes, KB, MB, GB, TB, PB)

* `--split=<number>`: Number of output files (default: 1)

* `--splitsize=<number>`: Size per file (required if split > 1)

* `--splitunit=<b|k|m|g|t|p>`: Unit for split size (default: b)

* `--stop`: Stop writing once the size limit is reached

* `--help`: Show usage help

### Examples

```
./fibonacci --file=seq.txt --size=256 --unit=b
./fibonacci --file=myfib.txt --size=50 --unit=k
./fibonacci --file=multi --split=3 --splitsize=10 --splitunit=k

```



## 🧪 Debugging Example 

Run with debug output:

```
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

* High-Performance Computing (HPC)

* Low-level systems programming

* Educational demonstration of assembly-level big integer arithmetic

* Compact benchmark tool for syscall-based I/O throughput



## 📜 License & Author 

**License:** 
![Logo de la licence CC BY-NC-ND](CC_BY-NC-ND.png)

**Author:** Thibaut LOMBARD

**GitHub:** [https://github.com/Lombard-Web-Services](https://github.com/Lombard-Web-Services)

**Project Repository:** [Big-Num-Fibo](https://github.com/Lombard-Web-Services/Big-Num-Fibo)

**Alias:** [@lombardweb](https://x.com/lombardweb)



## ⚖️ License Details 

This work is licensed under the **Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License**. To view a copy of this license, visit [http://creativecommons.org/licenses/by-nc-nd/4.0/](http://creativecommons.org/licenses/by-nc-nd/4.0/) or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

The main conditions of this license are:

* **Attribution (BY):** You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
* **NonCommercial (NC):** You may not use the material for commercial purposes.
* **NoDerivatives (ND):** If you remix, transform, or build upon the material, you may not distribute the modified material.
