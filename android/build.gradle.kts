allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(layout.projectDirectory.dir("../build"))

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
