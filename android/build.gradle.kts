allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// home_widget 0.9.1 declares androidx.glance:glance-appwidget:1.+, which
// currently resolves to 1.3.0-alpha01 and forces AGP 9.1 / compileSdk 37.
// Pin the native Android dependency to the latest stable Glance line compatible
// with this project's AGP 8.9 / compileSdk 36 release toolchain.
subprojects {
    configurations.configureEach {
        resolutionStrategy.force(
            "androidx.glance:glance:1.1.1",
            "androidx.glance:glance-appwidget:1.1.1",
        )
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
