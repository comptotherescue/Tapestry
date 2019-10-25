defmodule Tapestry.Starter do
    def start(numNode, numRequest) do
        genProcesses(numNode, numRequest)


    end

    def genProcesses(numNode, numRequest) do
        eightyPercentNodes = round(numNode*0.8)
        twentyPercentNodes = round(numNode*0.2)
        uniqIdlst = Enum.map(1..eightyPercentNodes, fn _x ->
            {:ok, pid} = Tapestry.Server.start_link()
            uniqId = :crypto.hash(:sha, inspect(pid)) |> Base.encode16 
            uniqId  = String.slice(uniqId,32,8) 
            Process.register(pid, String.to_atom(uniqId))
            uniqId 
        end)
        Enum.each(uniqIdlst, fn x -> 
        GenServer.cast(Process.whereis(String.to_atom(x)),{:updateNodes,uniqIdlst})
        end)
        IO.puts "Calculating hop count..."
        coverge_progress = Task.async(fn -> converge_progress(numNode*numRequest, numRequest, 0, uniqIdlst, twentyPercentNodes) end)
        Process.register(coverge_progress.pid, :supervisor)

        Enum.each(uniqIdlst, fn x -> 
        GenServer.cast(Process.whereis(String.to_atom(x)),{:route,x})
        end)

        #numRequest times Nodes
        Enum.each(uniqIdlst, fn sourceID -> 
            Enum.each(1..numRequest, fn _x->
                destId = uniqueDest(sourceID, uniqIdlst)
                send(Process.whereis(String.to_atom(sourceID)),{:routeAhead,destId, 0})
            end)
        end)
        Task.await(coverge_progress)
        

    end

    def uniqueDest(sourceID, totalNodes)do
        destId = Enum.random(totalNodes)
        if destId == sourceID do
            uniqueDest(sourceID, totalNodes)
        else
        destId
        end
    end

    def converge_progress(count, numRequest, max, uniqIdlst, twentyPercentNodes)do
    if count > 0 do
        receive do
            {:Converged, val} -> 
                if twentyPercentNodes > 0 do
                {:ok, pid} = Tapestry.Server.start_link()
                uniqId = :crypto.hash(:sha, inspect(pid)) |> Base.encode16 
                uniqId  = String.slice(uniqId,32,8) 
                Process.register(pid, String.to_atom(uniqId))
                uniqIdlst = uniqIdlst ++ [uniqId]
                #create routing table for new node
                GenServer.cast(Process.whereis(String.to_atom(uniqId)),{:updateNodes,uniqIdlst})
                GenServer.cast(Process.whereis(String.to_atom(uniqId)),{:route,uniqId})
                Enum.each(uniqIdlst, fn x -> 
                send(Process.whereis(String.to_atom(x)),{:updateRoutingTable, uniqId})
                end)
                Enum.each(1..numRequest, fn _x->
                    destId = uniqueDest(uniqId, uniqIdlst)
                    send(Process.whereis(String.to_atom(uniqId)),{:routeAhead, destId, 0})
                end)
            end
            if val > max do
                converge_progress(count-1, numRequest, val, uniqIdlst, twentyPercentNodes-1)
            else
            converge_progress(count-1, numRequest, max, uniqIdlst, twentyPercentNodes-1)
            end
            # code
        end
    else 
    #Kill all processes
        Enum.each(uniqIdlst, fn sourceID -> 
                send(Process.whereis(String.to_atom(sourceID)),{:kill})
        end)
    IO.puts "Maximum hop count is #{max}"
    end
    end
end