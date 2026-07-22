import Foundation
import SwiftData

enum ModelContainerFactory {
    static func makePersistent() throws -> ModelContainer {
        let schema = Schema(versionedSchema: OshiLifeSchemaV1.self)
        let configuration = ModelConfiguration(
            SharedConstants.databaseName,
            schema: schema,
            allowsSave: true,
            groupContainer: .identifier(SharedConstants.appGroupIdentifier),
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: OshiLifeMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func makeInMemory() throws -> ModelContainer {
        let schema = Schema(versionedSchema: OshiLifeSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: schema,
            migrationPlan: OshiLifeMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
