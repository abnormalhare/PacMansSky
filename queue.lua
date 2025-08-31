Queue = {}
Queue.list = {}

function Queue.add(func, delay)
    Queue.list[func] = delay
end

function Queue.remove(func)
    Queue.list[func] = nil
end

function Queue.update(dt)
    for k,v in pairs(Queue.list) do
        Queue.list[k] = v-dt;
        if v<dt then
            Queue.list[k]=nil
            k(dt)
        end
    end
end

addLoopCall(Queue.update)