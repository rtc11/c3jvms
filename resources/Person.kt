package person

internal class Person(
    private val first_name: String = "robin",
) {

    fun greet() {
        println("Hello $first_name")
    }
}

fun main() {
    val person = Person("robin")
    person.greet()
}

