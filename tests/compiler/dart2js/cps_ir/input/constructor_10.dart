// Method to test: generative_constructor(C#)
class C<T> {
  var x;
  C() : x = new D<T>();
}
class D<T> {
  foo() => T;
}
main() {
  print(new C<int>().x.foo());
}
