defmodule Test do
    def efun do
        m = 1000 |> :math.log2 |> :math.ceil |> trunc |> Kernel.+(2)
        IO.puts m
        n = 160-m
        r = trunc(:math.log2(1000))
        IO.inspect :crypto.hash(:sha, inspect(1020))
        :crypto.hash(:sha, inspect(102)) |> Base.encode16 

    end

    def genProcesses(numNode) do
        lst = Enum.map(1..numNode, fn x->
                uniqId = :crypto.hash(:sha, inspect(x)) |> Base.encode16 
                uniqId  = String.slice(uniqId,32,8)
                end)
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
end