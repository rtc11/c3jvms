# C3 JVMS

### Dissasemble classfiles:
run `c3c run main -- resources/Simple.class`

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

