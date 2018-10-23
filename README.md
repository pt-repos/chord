# Project 3
### Chord Simulation

A simulator for Chord p2p lookup algorithm writted in elixir.

#### Team members
1. Pulkit Tripathi 
   UFID: 9751-9461

#### Prerequisites
* [Elixir](https://elixir-lang.org/install.html)

#### Installing
* Install dependecies
```elixir
mix deps.get
````
* Compile the source
```elixir
mix compile
```
* Run proj3.exs
```bash
mix run proj3.exs <num_nodes> <num_requests>
```

For example for **200 nodes** with **10 requests each**
```bash
mix run proj3.exs 200 10
```

#### What is working?

Chord p2p lookup simulation runs successfully. For the purpose of this simulation, each node generates a random key for each request and measures the average number of hops required to lookup the key in the network.

SHA-1 is used for consistent hashing of keys. The hash values generated are 160 bits, which are then truncated depending on the size of the network. The hash value can be parted by bytes, i.e. the hash values are nx8 bits long (n -> 1..20). As a result the identifier space is 2<sup>nx8</sup>.

In cases where the set of nodes is sparse within the identifier space the average number of hops required to lookup a key is large. However, the average number of hops is less than log<sub>2</sub>(num_nodes) as the difference between the number of nodes and the size of identifier space is reduced.

For example:
For 1000 nodes, the average number of hops in my tests was in the range of 80 hops.
While for 10000, the average number of hops was consistently between 11-12.
The size of identifier space in both cases is 2<sup>16</sup>


Node failure model will be implemented in future release

#### Largest network tested

nodes: 15000 
requests per node: 10 
average_number_of_hops: 11.37
execution_time: 276.24 sec

Other results:
nodes: 10000
requests: 10
average number of hops: 11.28
execution_time: 185.34 sec

nodes: 200
requests: 10
average_number_of_hops: 4.61
execution_time: 12.38 sec

nodes: 1000
requests: 10
average_number_of_hops: 85.99
execution_time: 22.26 sec