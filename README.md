# GraphQL Entity Generator 🤖

A command line tool that automatically generates models with GraphQL. You need to specify in the -e argument the name of the entity you are interested in. If the entity has links to other entities, then they will be automatically generated.

### 1. Setup the config file

Add your GraphQL Entity Generator configuration to your `pubspec.yaml`.
An example is shown below. More complex examples [can be found in the example projects](https://github.com/thisisdingo/gql_entity_gen/tree/master/example).

```yaml
dev_dependencies:
  gql_entity_gen: ^0.1.0
```

### 2. Run the package

After setting up the configuration, all that is left to do is run the package.

```shell
flutter pub get
dart run gql_entity_gen -a http://localhost:4000/graphql -o lib/model.dart -e "User,Post,Comment"
```