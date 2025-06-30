module environment;

import std::collections::map;
import std::io;
import object;

struct Environment
{
    Allocator allocator;
    HashMap{String, Object} store;
    Environment* outer;
}

fn Environment* new(Allocator allocator)
{
    HashMap{String, Object} store;
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

fn Object? Environment.get(&self, String name)
{
    Object? obj = self.store[name];
    if (catch obj) {
        if (self.outer != null) return self.outer.get(name)!;
    }
    return obj;
}

fn Object Environment.set(&self, String name, Object value)
{
    self.store[name] = value;
    return value;
}
