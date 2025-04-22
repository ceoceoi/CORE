#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

void trim_whitespace(char *str) {
    int len = strlen(str);
    while (len > 0 && isspace(str[len - 1])) len--;
    str[len] = '\0';

    int start = 0;
    while (isspace(str[start])) start++;
    memmove(str, str + start, len - start + 1);
}

unsigned char translate_instruction(char *instruction) {
    trim_whitespace(instruction);
    printf("Instruction read: '%s'\n", instruction); // طباعة التعليمة للتحقق منها

    if (strcmp(instruction, "RA = RA + RB") == 0) {
        return 0b00000000;
    } else if (strcmp(instruction, "RB = RA + RB") == 0) {
        return 0b00000001;
    } else if (strcmp(instruction, "RA = RA - RB") == 0) {
        return 0b00000010;
    } else if (strcmp(instruction, "RB = RA - RB") == 0) {
        return 0b00000011;
    } else if (strcmp(instruction, "R0 = RA") == 0) {
        return 0b00000100;
    } else if (strcmp(instruction, "RA = imm") == 0) {
        return 0b00000110;
    } else if (strcmp(instruction, "RB = imm") == 0) {
        return 0b00000111;
    } else if (strcmp(instruction, "JC = imm") == 0) {
        return 0b00001101;
    } else if (strcmp(instruction, "J = imm") == 0) {
        return 0b00001110;
    } else {
        printf("Error: Unrecognized instruction: '%s'\n", instruction);
        return 0;
    }
}

FILE* open_file(const char *filename, const char *mode) {
    FILE *file = fopen(filename, mode);
    if (file == NULL) {
        printf("Error opening file: %s\n", filename);
        exit(1);
    }
    return file;
}

void handle_error(const char *message) {
    printf("Error: %s\n", message);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <input_file.asm>\n", argv[0]);
        return 1;
    }

    FILE *input_file = open_file(argv[1], "r");
    FILE *output_file = open_file("output.bin", "wb");

    char line[100];
    while (fgets(line, sizeof(line), input_file)) {
        trim_whitespace(line);
        unsigned char machine_code = translate_instruction(line);
        if (machine_code == 0) {
            handle_error("Unrecognized instruction.");
            continue;
        }
        fwrite(&machine_code, sizeof(machine_code), 1, output_file);
    }

    fclose(input_file);
    fclose(output_file);
    return 0;
}
