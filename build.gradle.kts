plugins {
    kotlin("jvm") version "2.1.21"
    application
}

repositories {
    mavenCentral()
}

kotlin {
    jvmToolchain(21)
}

sourceSets {
    main {
        kotlin.srcDirs("1_threads/task_1_kotlin")
    }
}

application {
    mainClass.set("MainKt")
}
