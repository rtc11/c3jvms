# C3 JVMS

### Dissasemble classfiles:
run `c3c run main -- resources/Simple.kt`

```cpp
fn void main(String[] args)
{
    @pool() {
        read_class(args);
    };
}
```

### REPL
run `./scripts/repl.sh`

