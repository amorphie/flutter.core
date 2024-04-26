enum NeoPageType {
  component('Component Page'),
  workflow('Workflow Page');

  const NeoPageType(this.type);

  final String type;
}
