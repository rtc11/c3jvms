module environment;

import std::collections::map;
import std::io;
import object;

struct Environment
{
    Allocator allocator;
    HashMap{String, Object} store;
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

fn Object? Environment.get(&self, String name)
{
    return self.store[name]!;
}

fn Object Environment.set(&self, String name, Object value)
{
    self.store[name] = value;
    return value;
}
