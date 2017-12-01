import java.io.BufferedInputStream
import java.io.FileInputStream
import java.net.URL
import java.nio.file.Files
import java.nio.file.Paths
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream

val releaseRestApiPage: String = URL("https://api.github.com/repos/JetBrains/kotlin/releases/latest").readText()

val downloadUrl = Regex("\"browser_download_url\":\\s*\\\"([^\"]+)\"").find(releaseRestApiPage)!!.groupValues[1]
val version = Regex("\"name\":\\s*\\\"([^\"]+)\"").find(releaseRestApiPage)!!.groupValues[1]

println("Downloading Kotlin ${version}")

val workingDirectory = Paths.get(System.getenv("DEVENV_CACHE"), "install", "kotlin")
val optDirectory = Paths.get(System.getenv("DEVENV_TOOLS"), "opt")
val directoryName = "kotlin-${version}"
val installDirectory = optDirectory.resolve(directoryName).toAbsolutePath()

if (Files.exists(installDirectory)) {
    error("Kotin ${version} is already installed")
}

val kotlinZip = workingDirectory.resolve("kotlin.zip")

Files.copy(BufferedInputStream(URL(downloadUrl).openStream()), kotlinZip)

val rootZipPath = Paths.get("kotlinc")
println("Unzipping to ${installDirectory}")

ZipInputStream(FileInputStream(kotlinZip.toFile())).use { zipStream ->
    var entry: ZipEntry? = zipStream.nextEntry
    while (entry != null) {
        val relativePath = rootZipPath.relativize(Paths.get(entry.name))
        val targetPath = installDirectory.resolve(relativePath)
        if (entry.isDirectory) {
            Files.createDirectories(targetPath)
        } else {
            Files.copy(zipStream.buffered(), targetPath)
            println("Unzipping ${relativePath}")
        }
        entry = zipStream.nextEntry
    }
}

val envIni = optDirectory.resolve("env.ini")
val envProperties: MutableList<String> = ArrayList()
if (Files.exists(envIni)) {
    envProperties.addAll(Files.readAllLines(envIni))
    envProperties.removeAll { line -> line.startsWith("KOTLIN_HOME=") }
}
envProperties.add("KOTLIN_HOME=\${env:DEVENV_TOOLS}/opt/${directoryName}")
envProperties.add("PATH=\${env:PATH};\${env:KOTLIN_HOME}/bin")
Files.write(envIni, envProperties)
