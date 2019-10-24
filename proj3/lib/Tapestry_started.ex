defmodule Tapestry.Starter do
    def start(numNode, numRequest) do
        genProcesses(numNode, numRequest)


    end

    def genProcesses(numNode, numRequest) do
     
        coverge_progress = Task.async(fn -> converge_progress(numNode*numRequest, 0) end)
        Process.register(coverge_progress.pid, :supervisor)

      
        uniqIdlst = Enum.map(1..numNode-5, fn x ->
            {:ok, pid} = Tapestry.Server.start_link()
            uniqId = :crypto.hash(:sha, inspect(pid)) |> Base.encode16 
            uniqId  = String.slice(uniqId,32,8) 
            Process.register(pid, String.to_atom(uniqId))
            uniqId 
        end)
        Enum.each(uniqIdlst, fn x -> 
        GenServer.cast(Process.whereis(String.to_atom(x)),{:updateNodes,uniqIdlst})
        end)

        #adding 5 new nodes
        newlst =  Enum.map(1..5, fn x ->
            {:ok, pid} = Tapestry.Server.start_link()
            uniqId = :crypto.hash(:sha, inspect(pid)) |> Base.encode16 
            uniqId  = String.slice(uniqId,32,8) 
            Process.register(pid, String.to_atom(uniqId))
            uniqId 
        end)
        totalNodes = uniqIdlst ++ newlst
        Enum.each(newlst, fn x -> 
        GenServer.cast(Process.whereis(String.to_atom(x)),{:updateNodes,totalNodes})
        end)

        Enum.each(uniqIdlst, fn x -> 
        GenServer.cast(Process.whereis(String.to_atom(x)),{:updateNodes,newlst})
        end)

        Enum.each(totalNodes, fn x -> 
        GenServer.cast(Process.whereis(String.to_atom(x)),{:route,x})
        end)
        IO.puts "hi"
        #numRequest times Nodes
        Enum.each(totalNodes, fn sourceID -> 
            Enum.each(1..numRequest, fn x->
                # IO.inspect totalNodes
                # IO.inspect sourceID
                destId = uniqueDest(sourceID, totalNodes)
                send(Process.whereis(String.to_atom(sourceID)),{:routeAhead,destId, 0})
            end)
        end)
        Task.await(coverge_progress)

        #Kill all processes
        Enum.each(totalNodes, fn sourceID -> 
                send(Process.whereis(String.to_atom(sourceID)),{:kill})
        end)

    end

    def uniqueDest(sourceID, totalNodes)do
        destId = Enum.random(totalNodes)
        if destId == sourceID do
            uniqueDest(sourceID, totalNodes)
        else
        destId
        end
    end

    def converge_progress(count, max)do
    if count > 0 do
        receive do
            {:Converged, val} -> 
            
            if val > max do
                IO.puts val
                converge_progress(count-1, val)
            else
            converge_progress(count-1, max)
            end
            # code
        end
    end
    end
    def genUniqueIds(numNode) do
        set = MapSet.new()
        set = Enum.map(numNode, fn x->
                uniqId = :crypto.hash(:sha, inspect(x)) |> Base.encode16 
                uniqId  = String.slice(uniqId,32,8)
                end)
    end
end