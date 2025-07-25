#!/bin/bash
# by Thibaut LOMBARD https://github.com/Lombard-Web-Services
# Script: gdb_fib_debug.sh
# Purpose: Run a predefined set of GDB commands and output to a file

# Create a temporary file to hold GDB commands
GDB_SCRIPT=$(mktemp)

cat <<'EOF' > "$GDB_SCRIPT"
set pagination off
file ./fibonacci
break generate_fibonacci
run --file=sequence.txt --size=256 --unit=b
print $rdi
print $rsi
print $rdx
break fibonacci.asm:84
continue
x/10b 0x404a10
x/10b 0x404b10
print $r10
print $rbx
break big_add
continue
x/10b 0x404c10
print $rax
break write_buffered
continue
print $rax
print /x *(long long *)0x404910
break big_to_str
continue
print $rax
print /x *(long long *)0x404938
quit
EOF

# Run GDB with the temporary script
gdb -q -batch -x "$GDB_SCRIPT"

# Clean up temporary file
rm -f "$GDB_SCRIPT"
