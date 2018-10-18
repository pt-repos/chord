{:ok, supervisor} = Chord.Supervisor.start_link([])
{:ok, register} = Chord.NodeRegister.start_link([])
{:ok, node_pids} = Chord.Supervisor.start_nodes(supervisor, 3, register)

Enum.each(node_pids, fn node_pid-> 
	IO.inspect :sys.get_state(node_pid)
end)

{:ok, node1} = Chord.Node.start_link([node_register: register])
:sys.get_state(node1)