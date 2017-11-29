println("\nWelcome to the setup script to install your new development environment")
println("\nEnjoy! ;)\n")

println("Environment variables:")
printEnvVal("DEVENV_TOOLS")
printEnvVal("DEVENV_SETTINGS")
printEnvVal("DEVENV_HOME")
printEnvVal("DEVENV_CACHE")

fun printEnvVal(key: String) {
    println(key + " = " + System.getenv(key))
}
