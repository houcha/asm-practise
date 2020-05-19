#include <unordered_set>
#include <cassert>
#include <cstdlib>
#include <cstdio>
#include <climits>
#include <random>
#include "set_int_inl.hpp"

struct Array {
  int* data;
  size_t size;
};

size_t get_file_size(FILE* fp) {
  fseek(fp, 0L, SEEK_END);
  size_t sz = ftell(fp);
  rewind(fp);
  return sz;
}

Array load_data(const char* dist) {
  FILE* file = fopen(dist, "r");
  size_t size = get_file_size(file) / sizeof(int);
  printf("%s size: %d\n", dist, size);
  Array array;
  array.data = (int*)calloc(size, sizeof(int));
  array.size = size;
  fread(array.data, size, sizeof(int), file);
  return array;
}

int test(const char* dist, Array search_data) {
  Array array = load_data(dist);
  int* data = array.data;
  size_t size = array.size;

  SetInt set;
  for (size_t i = 0; i < size; ++i) {
    set.Insert(data[i]);
  }

  for (size_t i = 0; i < size; ++i) {
    set.Find(data[i]);
  }

  for (size_t i = 0; i < search_data.size; ++i) {
    set.Find(search_data.data[i]);
  }

  free(data);
}

int main() {
  Array search_data = load_data("distributions/search_data");
  test("distributions/uniform", search_data);
  test("distributions/exp", search_data);
  test("distributions/normal", search_data);
}

