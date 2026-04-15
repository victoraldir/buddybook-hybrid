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

rootProject.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir("../../build").get())

subprojects {
    project.layout.buildDirectory.value(rootProject.layout.buildDirectory.get().dir(project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
