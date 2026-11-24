// Checks that the compiler, <meta> and the bundled libc++ work together.
// Adapted from libcxx/test/std/experimental/reflection/p2996-ex-enum-to-string.pass.cpp
#include <meta>

#include <cstdio>
#include <string>
#include <type_traits>

template <typename E>
  requires std::is_enum_v<E>
constexpr std::string enum_to_string(E value) {
  std::string result = "<unnamed>";
  template for (constexpr auto e : define_static_array(enumerators_of(^^E))) {
    if (value == [:e:])
      result = std::string(identifier_of(e));
  }
  return result;
}

int main() {
  enum Color { red, green, blue };
  static_assert(enum_to_string(Color::red) == "red");
  std::printf("%s %s %s\n", enum_to_string(Color::green).c_str(),
              enum_to_string(Color::blue).c_str(),
              enum_to_string(Color(42)).c_str());
  return enum_to_string(Color::blue) == "blue" ? 0 : 1;
}
