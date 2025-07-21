module environment;

import std::collections::map;
import std::io;
import runtime;

struct Environment
{
    Allocator allocator;
    HashMap{String, RuntimeValue} store;
    Environment* outer;
}

fn Environment* new(Allocator allocator)
{
    HashMap{String, RuntimeValue} store;
    store.tinit();
    return allocator::new(allocator, Environment, { 
        .allocator = allocator,
        .store = store,
    });
}

fn Environment* new_enclosed(Environment* outer, Allocator allocator)
{
    Environment* env = new(allocator);
    env.outer = outer;
    return env;
}

fn RuntimeValue? Environment.get(&self, String name)
{
    RuntimeValue? obj = self.store[name];
    if (catch obj) {
        if (self.outer != null) return self.outer.get(name)!;
    }
    return obj;
}

fn RuntimeValue Environment.set(&self, String name, RuntimeValue value)
{
    self.store[name] = value;
    return value;
}
