#include <unordered_set>
#include <cassert>
#include <cstdlib>
#include <cstdio>
#include <climits>
#include <random>
#include "set_int_inl.hpp"


size_t get_file_size(FILE* fp) {
  fseek(fp, 0L, SEEK_END);
  size_t sz = ftell(fp);
  rewind(fp);
  return sz;
}

int test(const char* dist) {
  FILE* file = fopen(dist, "r");
  size_t size = get_file_size(file);
  printf("%s size: %d\n", dist, size/sizeof(int));
  int* data = (int*)calloc(size, sizeof(int));
  fread(data, size, sizeof(int), file);

  std::unordered_set<int> libset;
  SetInt set;
  for (size_t i = 0; i < size; ++i) {
    libset.insert(data[i]);
    set.Insert(data[i]);
  }

  for (size_t i = 0; i < size; ++i) {
    assert(set.Find(data[i]) != 0);
  }

  std::default_random_engine generator;
  std::uniform_int_distribution<int> distribution(INT_MIN, INT_MAX);
  auto dice = std::bind(distribution, generator);

  for (size_t i = 0; i < size; ++i) {
    int value = dice();
    if (libset.count(value) != 0) {
      assert(set.Find(value) != 0);
    } else {
      assert(set.Find(value) == 0);
    }
  }
  free(data);
}

int main() {
  test("distributions/uniform");
  test("distributions/exp");
  test("distributions/normal");
}

