defmodule Tapestry.Entry do
    def main(args) do
        cond do
        length(args) == 2 ->
            numNode = Enum.at(args, 0)
            numRequest = Enum.at(args, 1)
            Tapestry.Starter.start(String.to_integer(numNode), String.to_integer(numRequest))
        true -> IO.puts("Argument error!")
    end 
    end
end