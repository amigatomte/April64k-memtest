#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s input.prg output.prg\n", argv[0]);
        return 1;
    }
    
    FILE *fin = fopen(argv[1], "rb");
    if (!fin) {
        perror("Error opening input file");
        return 1;
    }
    
    FILE *fout = fopen(argv[2], "wb");
    if (!fout) {
        perror("Error opening output file");
        fclose(fin);
        return 1;
    }
    
    // Skip the first two bytes (load address)
    if (fseek(fin, 2, SEEK_SET) != 0) {
        perror("Error seeking in input file");
        fclose(fin);
        fclose(fout);
        return 1;
    }
    
    // Copy the remainder of the file to the output
    char buffer[4096];
    size_t bytesRead;
    while ((bytesRead = fread(buffer, 1, sizeof(buffer), fin)) > 0) {
        if (fwrite(buffer, 1, bytesRead, fout) != bytesRead) {
            perror("Error writing to output file");
            fclose(fin);
            fclose(fout);
            return 1;
        }
    }
    
    fclose(fin);
    fclose(fout);
    return 0;
}
