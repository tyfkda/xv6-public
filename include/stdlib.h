#pragma once

void exit(int) __attribute__((noreturn));

void* malloc(uint);
void free(void*);

int atoi(const char*);
