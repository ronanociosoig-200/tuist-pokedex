import ProjectDescription

let workspace = Workspace(
    name: "PokedexWorkspace",
    projects: ["./**"],
    generationOptions: .options(
        autogeneratedWorkspaceSchemes:
                .enabled(codeCoverageMode: .all,
                         testingOptions: [
                            .parallelizable,
                            .randomExecutionOrdering])
    )
)
