//
// kotlinc Main.kt -include-runtime -d Main.jar
// java -jar Main.jar
//
fun main() {
    val names = listOf("World", "Kotlin", "User")

    for (name in names) {
        if (name == "World") {
            println("Hello, $name!")
        } else {
            println("Hello, $name. Nice to meet you!")
        }
    }
}

