allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep Android outputs under this Flutter project's build/ so flutter tool can find APKs.
val projectBuildDir = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.set(projectBuildDir)

subprojects {
    project.layout.buildDirectory.set(projectBuildDir.dir(project.name))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
