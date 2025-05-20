DupeA = DupeA or {}

function DupeA.PrintDebug(text)
    if not getDebug() then return end
    print(text)
end
