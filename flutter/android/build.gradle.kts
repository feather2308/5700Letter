buildscript {
    // [핵심] 여기에 repositories가 꼭 있어야 플러그인을 다운받습니다!
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // 기존 안드로이드 빌드 툴 (버전은 다를 수 있음, 그대로 두세요)
        classpath("com.android.tools.build:gradle:8.1.0")
        // 구글 서비스 플러그인
        classpath("com.google.gms:google-services:4.3.15")
    }
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
