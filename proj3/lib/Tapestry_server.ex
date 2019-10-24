defmodule Tapestry.Server do
use GenServer

    def start_link() do
        GenServer.start_link(__MODULE__,%{})
    end
    def init(state)do 
        state = %{}
        {:ok, state}
    end

    def handle_cast({:updateNodes, uniqueIdLst}, state) do
        rtable = createRouting(self(), uniqueIdLst, state)
        state = rtable
        {:noreply, state}
    end
    
    def handle_cast({:route, uniqueId}, state)do
        recBlock(uniqueId, state)
        {:noreply, state}
    end

    def recBlock(uniqueId, state)do
        receive do
            {:routeAhead, destId, count} ->
            if uniqueId == destId do
                send(Process.whereis(:supervisor), {:Converged, count})
            else 
                rtable = state
                {i, j} = findPosition(uniqueId, destId)
                
                send(Process.whereis(String.to_atom((Map.get(rtable, {i, j})))), {:routeAhead, destId, count+1})
            end
            recBlock(uniqueId, state)
            {:kill} ->
             Process.exit(self(), :normal)
        end
        
    end
    def createRouting(pid, uniqueIdLst, state) do
          rtable = state
          {:registered_name, uniqueId} =  Process.info(pid, :registered_name)
          uniqueId = Atom.to_string(uniqueId)

                rtable = Enum.reduce(uniqueIdLst,rtable, fn x, acc->
                {i, j} = findPosition(uniqueId, x)
                cond do
                    Map.get(acc, {i, j}) == nil -> 
                    Map.put(acc, {i, j}, x)
                true-> 
                    Map.replace!(acc, {i, j}, x)        
                end
               
        end)
        rtable
    end 

 def minDiff(uniqueId, element1, element2)do
        uID = String.to_integer(uniqueId, 16)
        eleNum = String.to_integer(element1, 16)
        eleNum2 = String.to_integer(element2, 16)
        if abs(uID- eleNum) > abs(uID - eleNum2) do
            true
        else
            false
        end
    end

    def prefixFinder(uid, gid, 8)do
        8
    end
    def prefixFinder(uid, gid, i)do

        if String.at(uid,i) == String.at(gid, i) do
            prefixFinder(uid, gid, i+1)
        else
            i
        end             
    end

    def findPosition(uniqueId, guid)do
        i = prefixFinder(uniqueId, guid, 0)
        j = String.at(guid, i)
        {i, j}
    end
end