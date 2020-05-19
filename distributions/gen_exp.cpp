#include <cstdio>
#include <climits>
#include <random>
#include <functional>

int main(int argc, char** argv) {
  FILE* file = fopen(argv[1], "w");
  size_t count = strtol(argv[2], NULL, 10);

  std::default_random_engine generator;
  std::exponential_distribution<double> distribution(0.5);
  auto dice = std::bind(distribution, generator);

  int* data = (int*)calloc(count, sizeof(int));
  for (size_t i = 0; i < count; ++i) {
    data[i] = int(dice());
  }

  fwrite(data, sizeof(int), count, file);
  fclose(file);
  return 0;
}

