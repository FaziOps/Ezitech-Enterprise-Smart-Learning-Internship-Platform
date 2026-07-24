allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
    val configureAction = Action<Project> {
        val isAndroid = plugins.hasPlugin("com.android.application") || 
                        plugins.hasPlugin("com.android.library")
        if (isAndroid) {
            val android = extensions.findByName("android")
            if (android != null) {
                val baseExtension = android as? com.android.build.gradle.BaseExtension
                if (baseExtension != null) {
                    baseExtension.compileSdkVersion(36)
                    if (baseExtension.namespace.isNullOrEmpty()) {
                        val groupStr = project.group.toString()
                        baseExtension.namespace = if (groupStr.isNotEmpty()) {
                            groupStr
                        } else {
                            "com.example.${project.name.replace("-", "_").replace(" ", "_")}"
                        }
                    }
                }
            }
        }
    }

    if (state.executed) {
        configureAction.execute(this)
    } else {
        afterEvaluate {
            configureAction.execute(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
