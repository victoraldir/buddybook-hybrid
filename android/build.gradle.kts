allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.all {
        resolutionStrategy {
            // Force 16KB aligned versions for ML Kit and related Google Play Services
            force("com.google.mlkit:barcode-scanning:17.3.0")
            force("com.google.mlkit:common:18.11.0")
            force("com.google.mlkit:vision-common:17.3.0")
            force("com.google.mlkit:image-labeling-common:18.1.0")
            force("com.google.mlkit:vision-interfaces:16.3.0")
            force("com.google.android.gms:play-services-mlkit-barcode-scanning:18.3.1")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
