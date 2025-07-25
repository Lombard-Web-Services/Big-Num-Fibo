#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <ctype.h>

// External assembly function
extern int generate_fibonacci(char *filename, long size_limit, int fd);

void print_help() {
printf("Usage: ./fibonacci [options]\n");
printf("Options:\n");
printf("  --file=<filename>        Output file (default: fib.txt)\n");
printf("  --size=<number>          Total size limit (default: 1048576)\n");
printf("  --unit=<b|k|m|g|t|p>     Unit for size (bytes, KB, MB, GB, TB, PB; default: b)\n");
printf("  --split=<number>         Number of split files (default: 1)\n");
printf("  --splitsize=<number>     Size per split (required if split > 1)\n");
printf("  --splitunit=<b|k|m|g|t|p> Unit for split size (default: b)\n");
printf("  --stop                   Stop at total size or per-split size\n");
printf("  --help                   Show this help\n");
printf("Examples:\n");
printf("  ./fibonacci --file=out.txt --size=256 --unit=b\n");
printf("  ./fibonacci --file=myfib.txt --size=50 --unit=k\n");
printf("  ./fibonacci --file=fib --split=3 --splitsize=10 --splitunit=k\n");
exit(0);
}

long parse_size(const char *str, const char *unit, const char *context) {
char *endptr;
errno = 0;
long value = strtol(str, &endptr, 10);
if (errno != 0 || *endptr != '\0' || value <= 0) {
fprintf(stderr, "Invalid %s: %s\n", context, str);
exit(1);
}

char unit_lower[16];
strncpy(unit_lower, unit, sizeof(unit_lower) - 1);
unit_lower[sizeof(unit_lower) - 1] = '\0';
for (char *p = unit_lower; *p; ++p) {
*p = tolower(*p);
}

long multiplier = 1;
if (strcmp(unit_lower, "b") == 0) {
multiplier = 1;
} else if (strcmp(unit_lower, "k") == 0) {
multiplier = 1024;
} else if (strcmp(unit_lower, "m") == 0) {
multiplier = 1024 * 1024;
} else if (strcmp(unit_lower, "g") == 0) {
multiplier = 1024L * 1024 * 1024;
} else if (strcmp(unit_lower, "t") == 0) {
multiplier = 1024L * 1024 * 1024 * 1024;
} else if (strcmp(unit_lower, "p") == 0) {
multiplier = 1024L * 1024 * 1024 * 1024 * 1024;
} else {
fprintf(stderr, "Invalid unit for %s: %s\n", context, unit);
exit(1);
}

return value * multiplier;
}

int main(int argc, char *argv[]) {
char *filename = "fib.txt";
char *size_str = "1048576";
char *unit = "b";
long split_count = 1;
char *splitsize_str = NULL;
char *splitunit = "b";
int stop = 0;

struct option long_options[] = {
{"file", required_argument, NULL, 'f'},
{"size", required_argument, NULL, 's'},
{"unit", required_argument, NULL, 'u'},
{"split", required_argument, NULL, 'p'},
{"splitsize", required_argument, NULL, 'z'},
{"splitunit", required_argument, NULL, 'y'},
{"stop", no_argument, NULL, 't'},
{"help", no_argument, NULL, 'h'},
{0, 0, 0, 0}
};

int opt;
while ((opt = getopt_long(argc, argv, "", long_options, NULL)) != -1) {
switch (opt) {
case 'f': filename = optarg; break;
case 's': size_str = optarg; break;
case 'u': unit = optarg; break;
case 'p': split_count = atol(optarg); break;
case 'z': splitsize_str = optarg; break;
case 'y': splitunit = optarg; break;
case 't': stop = 1; break;
case 'h': print_help(); break;
default:
fprintf(stderr, "Unknown option\n");
exit(1);
}
}

if (split_count < 1) {
fprintf(stderr, "Split count must be at least 1\n");
exit(1);
}
if (split_count > 1 && splitsize_str == NULL) {
fprintf(stderr, "Splitsize required when split > 1\n");
exit(1);
}
if (strlen(filename) == 0) {
fprintf(stderr, "Filename cannot be empty\n");
exit(1);
}

long total_size = parse_size(size_str, unit, "size");
long splitsize = (splitsize_str != NULL) ? parse_size(splitsize_str, splitunit, "splitsize") : total_size;

if (stop && split_count > 1) {
long max_per_split = total_size / split_count;
if (splitsize > max_per_split) {
splitsize = max_per_split;
}
}

long bytes_written = 0;
for (long i = 0; i < split_count; i++) {
char out_filename[256];
if (split_count > 1) {
snprintf(out_filename, sizeof(out_filename), "%s-%ld.txt", filename, i);
} else {
snprintf(out_filename, sizeof(out_filename), "%s", filename);
}

fprintf(stderr, "Opening %s with size %ld bytes\n", out_filename, split_count > 1 ? splitsize : total_size);

int fd = open(out_filename, O_WRONLY | O_CREAT | O_TRUNC, 0644);
if (fd < 0) {
fprintf(stderr, "Failed to open %s: %s\n", out_filename, strerror(errno));
exit(1);
}

long size_for_this_split = (split_count > 1) ? splitsize : total_size;
if (stop && bytes_written + size_for_this_split > total_size) {
size_for_this_split = total_size - bytes_written;
}
if (size_for_this_split <= 0) {
fprintf(stderr, "Skipping %s: size limit reached\n", out_filename);
close(fd);
break;
}

fprintf(stderr, "Calling generate_fibonacci for %s, size=%ld, fd=%d\n", out_filename, size_for_this_split, fd);
int result = generate_fibonacci(out_filename, size_for_this_split, fd);
if (result != 0) {
fprintf(stderr, "Failed to generate Fibonacci for %s: result=%d\n", out_filename, result);
close(fd);
continue; // Continue to next split instead of exiting
}

bytes_written += size_for_this_split;
close(fd);

if (stop && bytes_written >= total_size) {
fprintf(stderr, "Stopping: total size %ld reached\n", total_size);
break;
}
}

return 0;
}
