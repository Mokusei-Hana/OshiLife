import SwiftData

enum OshiLifeSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [LiveEvent.self] }
}

enum OshiLifeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [OshiLifeSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
