function fib(n::Int)
    n <= 1 ? 1 : fib(n - 1) + fib(n - 2)
end
function fibm(fn::Function)
    local bag = Dict(0 => 1, 1 => 1, 2 => 2, 3 => 5)
    return function fib2(m)
        stored = get(bag, m, nothing)
        if isnothing(stored)
            f = fib(m)

            bag = Dict(bag..., m => f)
            f
        else
            println("hit")
            stored
        end
    end
end

fb = fibm()
fb(5)
bag
